//
//  UserDirectory.swift
//  MyMessages
//
//  Created by marobert on 2020-11-30.
//

import Foundation
import MessageKit

// TODO: update all this stuff with your own resource

let RESOURCE_URL = "https://mattstestresource.communication.azure.com/"
let USER_ACCESS_TOKEN = "TODO UPDATE WITH VALID TOKEN"

public struct User: SenderType {
    public let senderId: String
    public let displayName: String
    public let initials: String
}

class UserDirectory {
    // TODO: mapping or user details to SPOOL User IDs
    private static let users = [
        "8:spool:8d0de54a-ca74-4b37-89ea-75a8ab565166_cc01aa-05009e50f8": User(
            senderId: "8:spool:8d0de54a-ca74-4b37-89ea-75a8ab565166_cc01aa-05009e50f8",
            displayName: "Julia Schneiderman",
            initials: "JS"
        ),
        "8:spool:8d0de54a-ca74-4b37-89ea-75a8ab565166_e701aa-0f00c7d0f0": User(
            senderId: "8:spool:8d0de54a-ca74-4b37-89ea-75a8ab565166_e701aa-0f00c7d0f0",
            displayName: "Matthew Robertson",
            initials: "MR"
        ),
    ];
    
    public static func getSender(fromId: String) -> User {
        return users[fromId]!
    }
    
    public static func currentUser() -> User {
        // TODO: replace with spool user id that corresponds to USER_ACCESS_TOKEN
        return getSender(fromId: "8:spool:8d0de54a-ca74-4b37-89ea-75a8ab565166_cc01aa-05009e50f8")
    }
    
    public static func currentUserToken() -> String {
        return USER_ACCESS_TOKEN
    }
}
