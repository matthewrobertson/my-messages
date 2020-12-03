//
//  Message.swift
//  MyMessages
//
//  Created by marobert on 2020-11-30.
//

import Foundation
import MessageKit
import AzureCommunicationChat

public struct Message: MessageType {

    /// The unique identifier for the message.
    public var messageId: String

    /// The date the message was sent.
    public var sentDate: Date = Date()
    
    /// The sender of the message.
    public var sender: SenderType

    /// The kind of message and its underlying kind.
    public var kind: MessageKind
}

extension Message {
    init(acsMessage: ChatMessage) {
        let formatter1 = DateFormatter()
        formatter1.dateStyle = .short
        print(formatter1.string(from: acsMessage.createdOn!))
        self.init(
            messageId: acsMessage.id!,
            sentDate: acsMessage.createdOn ?? Date(),
            sender: UserDirectory.getSender(fromId: acsMessage.senderId!),
            kind: .text(acsMessage.content ?? "")
        )
    }
}
