//
//  ChatThreadViewModel.swift
//  MyMessages
//
//  Created by marobert on 2020-11-29.
//

import Foundation
import MessageKit
import AzureCommunicationChat
import AzureCore

class ThreadClient {
    
    private let threadId: String
    private let chatClient: AzureCommunicationChatClient
    private var knownMessages: Set<String> = []
    private var timer: Timer? = nil
    private var isLoading = false
    private var earliestPage: PagedCollection<ChatMessage>?
    
    init(threadId: String, chatClient: AzureCommunicationChatClient) {
        self.threadId = threadId
        self.chatClient = chatClient

    }
    
    public func onMessage(_ completionHandler: @escaping (Message) -> Void) {
        if let timer = timer {
            timer.invalidate()
        }
        self.timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { (timer) in
            self.fetchMessages { result in
                if case let .success(messages) = result {
                    messages.forEach(completionHandler)
                }
            }
        }
    }
    
    deinit {
        if let timer = timer {
            timer.invalidate()
            self.timer = nil
        }
    }
    
    private func markMessagesAsSeen(_ messages: [Message]) {
        self.knownMessages.formUnion(messages.map { $0.messageId })
    }
    
}


// MARK: - Actions

extension ThreadClient {
    public func loadMore(completionHandler: @escaping ([Message]) -> Void) {
        if (isLoading || earliestPage == nil || earliestPage!.isExhausted) {
            completionHandler([])
            return
        }
        isLoading = true
        earliestPage!.nextPage { result in
            switch result {
            case let .success(messages):
                let messageModels = messages
                    .filter { $0.type == "Text" }
                    .filter { !self.knownMessages.contains($0.id!) }
                    .reversed()
                    .map { Message(acsMessage: $0) }
                
                self.markMessagesAsSeen(messageModels)
                
                completionHandler(messageModels)
                
            case .failure(_):
                print("failed to fetch messages")
                completionHandler([])
            }
        }
        self.isLoading = false
    }
    
    public func fetchMessages(completionHandler: @escaping (Result<[Message], Error>) -> Void) {
        let options = AzureCommunicationChatService.ListChatMessagesOptions(
            maxPageSize: 20
        )
        chatClient.listChatMessages(chatThreadId: threadId, withOptions: options) { result, _ in
            switch result {
            case let .success(listMessagesResponse):
                if (self.earliestPage == nil) {
                    self.earliestPage = listMessagesResponse
                }
                let messages = listMessagesResponse.items?
                    .filter { $0.type == "Text" }
                    .filter { !self.knownMessages.contains($0.id!) }
                    .reversed()
                    .map { Message(acsMessage: $0) }
                    
                self.markMessagesAsSeen(messages ?? [])
                
                completionHandler(.success(messages ?? []))

            case let .failure(error):
                completionHandler(.failure(error))
            }
        }
    }
    
    public func sendChatMessage(content: String, completionHandler: @escaping (Result<Message, Error>) -> Void) {
        let messageRequest = SendChatMessageRequest(
            priority: ChatMessagePriority.high,
            content: content,
            senderDisplayName: UserDirectory.currentUser().displayName
        )
        
        let options = AzureCommunicationChatService.SendChatMessageOptions(
            clientRequestId: UUID().uuidString
        )

        chatClient.send(chatMessage: messageRequest, chatThreadId: threadId, withOptions: options) { result, _ in
            switch result {
            case let .success(createMessageResponse):
                let messageModel = Message(
                    messageId: createMessageResponse.id!,
                    sender: UserDirectory.currentUser(),
                    kind: .text(content))
                
                self.markMessagesAsSeen([messageModel])
                
                completionHandler(.success(messageModel))

            case let .failure(error):
                completionHandler(.failure(error))
            }
        }
    }
}



//    private func createThread() {
//        if let chatClient = chatClient {
//            let thread = CreateChatThreadRequest(
//                topic: "General",
//                members: [
//                    ChatThreadMember(
//                        id: "8:spool:8d0de54a-ca74-4b37-89ea-75a8ab565166_e701aa-0f00c7d0f0",
//                        // Id of this needs to match with the Auth token
//                        displayName: "Matthew Robertson"
//                    ),
//                    ChatThreadMember(
//                        id: "8:spool:8d0de54a-ca74-4b37-89ea-75a8ab565166_cc01aa-05009e50f8",
//                        // Id of this needs to match with the Auth token
//                        displayName: "Julia Schneiderman"
//                    ),
//                ]
//            )
//
//            chatClient.create(chatThread: thread) { result, _ in
//                switch result {
//                case let .success(createThreadResponse):
//                    var threadId: String? = nil
//                    for response in createThreadResponse.multipleStatus ?? [] {
//                        if response.id?.hasSuffix("@thread.v2") ?? false,
//                            response.type ?? "" == "Thread" {
//                            threadId = response.id
//                            print(threadId)
//                        }
//                    }
//                    // Take further action
//
//                case let .failure(_):
//                    print("Failed to create thread")
//                    // Display error message
//                }
//            }
//        }
//    }
