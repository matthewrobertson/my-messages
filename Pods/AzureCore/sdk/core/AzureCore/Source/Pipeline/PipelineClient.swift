// --------------------------------------------------------------------------
//
// Copyright (c) Microsoft Corporation. All rights reserved.
//
// The MIT License (MIT)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the ""Software""), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//
// --------------------------------------------------------------------------

import Foundation

/// Protocol for baseline options for individual service clients.
public protocol ClientOptions {
    /// The API version of the service to invoke.
    var apiVersion: String { get }
    /// The `ClientLogger` to be used by the service client.
    var logger: ClientLogger { get }
    /// Options for configuring telemetry sent by the service client.
    var telemetryOptions: TelemetryOptions { get }
    /// Global transport options
    var transportOptions: TransportOptions { get }
    /// The default dispatch queue on which to call all completion handlers. Defaults to `DispatchQueue.main`.
    var dispatchQueue: DispatchQueue? { get }
}

/// Protocol for baseline options for individual client API calls.
public protocol RequestOptions {
    /// A client-generated, opaque value with 1KB character limit that is recorded in analytics logs.
    /// Highly recommended for correlating client-side activites with requests received by the server.
    var clientRequestId: String? { get }
    /// A token used to make a best-effort attempt at canceling a request.
    var cancellationToken: CancellationToken? { get }
    /// A dispatch queue on which to call the completion handler. Defaults to `DispatchQueue.main`.
    var dispatchQueue: DispatchQueue? { get }
    /// A `PipelineContext` object to associate with the request.
    var context: PipelineContext? { get set }
}

/// Base class for all pipeline-based service clients.
open class PipelineClient {
    // MARK: Properties

    internal var pipeline: Pipeline
    public var endpoint: URL
    public var logger: ClientLogger
    public var commonOptions: ClientOptions

    // MARK: Initializers

    public init(
        endpoint: URL,
        transport: TransportStage,
        policies: [PipelineStage],
        logger: ClientLogger,
        options: ClientOptions
    ) {
        self.endpoint = endpoint.hasDirectoryPath ? endpoint : endpoint.appendingPathComponent("/")
        self.logger = logger
        self.pipeline = Pipeline(transport: transport, policies: policies, withOptions: options.transportOptions)
        self.commonOptions = options
    }

    // MARK: Public Methods

    public func url(forTemplate templateIn: String, withKwargs kwargs: [String: String]? = nil) -> URL? {
        var template = templateIn
        if template.hasPrefix("/") { template = String(template.dropFirst()) }
        var urlString = endpoint.absoluteString
        if template.starts(with: urlString) {
            urlString = template
        } else {
            urlString += template
        }
        if let urlKwargs = kwargs {
            for (key, value) in urlKwargs {
                urlString = urlString.replacingOccurrences(of: "{\(key)}", with: value)
            }
        }
        return URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))
    }

    public func request(
        _ request: HTTPRequest,
        context: PipelineContext?,
        completionHandler: @escaping HTTPResultHandler<Data?>
    ) {
        let pipelineRequest = PipelineRequest(request: request, logger: logger, context: context)
        pipeline.run(request: pipelineRequest) { result, httpResponse in
            switch result {
            case let .success(pipelineResponse):
                let deserializedData = pipelineResponse.value(forKey: .deserializedData) as? Data

                // invalid status code is a failure
                let statusCode = httpResponse?.statusCode ?? -1
                let allowedStatusCodes = pipelineResponse.value(forKey: .allowedStatusCodes) as? [Int] ?? [200]
                if !allowedStatusCodes.contains(httpResponse?.statusCode ?? -1) {
                    self.logError(withData: deserializedData)
                    let error = AzureError.service("Service returned invalid status code [\(statusCode)].", nil)
                    completionHandler(.failure(error), httpResponse)
                } else {
                    if let deserialized = deserializedData {
                        completionHandler(.success(deserialized), httpResponse)
                    } else if let data = httpResponse?.data {
                        completionHandler(.success(data), httpResponse)
                    }
                }
            case let .failure(error):
                completionHandler(.failure(error), httpResponse)
            }
        }
    }

    // MARK: Internal Methods

    internal func logError(withData data: Data?) {
        guard let data = data else { return }
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return }
        guard let errorDict = json as? [String: Any] else { return }
        logger.debug {
            var errorStrings = [String]()
            for (key, value) in errorDict {
                errorStrings.append("\(key): \(value)")
            }
            return errorStrings.joined(separator: "\n")
        }
    }
}
