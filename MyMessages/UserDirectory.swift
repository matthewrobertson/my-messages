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
let USER_ACCESS_TOKEN = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjEwMiIsInR5cCI6IkpXVCJ9.eyJza3lwZWlkIjoic3Bvb2w6OGQwZGU1NGEtY2E3NC00YjM3LTg5ZWEtNzVhOGFiNTY1MTY2X2NjMDFhYS0wNTAwOWU1MGY4Iiwic2NwIjoxNzkyLCJjc2kiOiIxNjA3MDIyNTExIiwiaWF0IjoxNjA3MDIyNTExLCJleHAiOjE2MDcxMDg5MTEsImFjc1Njb3BlIjoiY2hhdCIsInJlc291cmNlSWQiOiI4ZDBkZTU0YS1jYTc0LTRiMzctODllYS03NWE4YWI1NjUxNjYifQ.zhWOeEQufrp9ikL6uOIPtgeXnHDcTyb9d9NWRk4aczxhgrWobBtMYoAmFYSRVJnIqXEqPGvtmGtfUoweNlqgKJM5xBDagdWxeMfFCQ74qWtOUNYR9A25heYWhjdNhyJeUCX8Qsmj4BI0HPVyEO1HB_ST-RkeQEsoH-WEVpr43D8CMdmu7mPla7ZBqwT1AwBP3j2dsOedQJf5lO7cKq1W8P2ulIsB6P_pc-tQEO2zYNwPrklZN27EaoLg8v7j83dwmCZ7SXPh4xdDIF4ACJD6hLla24rsTIY3aDMMqnYWdqfDOktuAaknLTof3Qrjzaph11Hd1kT-9KYPaMU_0xXNbg"

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
