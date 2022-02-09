//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSCognitoIdentityProvider

public struct SignOutEvent: StateMachineEvent {
    public var data: Any?

    public enum EventType: Equatable {
        public static func == (lhs: SignOutEvent.EventType, rhs: SignOutEvent.EventType) -> Bool {
            return false
        }

        case signOutGlobally(SignedInData)
        case revokeToken(SignedInData)
        case signOutLocally(SignedInData)
        case signedOutSuccess
        case signedOutFailure(AuthenticationError)
    }

    public let id: String
    public let eventType: EventType
    public let time: Date?

    public var type: String {
        switch eventType {
        case .signOutGlobally:
            return "SignOutEvent.signOutGlobally"
        case .revokeToken:
            return "SignOutEvent.revokeToken"
        case .signOutLocally:
            return "SignOutEvent.clearCredentialStore"
        case .signedOutSuccess:
            return "SignOutEvent.signedOutSuccess"
        case .signedOutFailure:
            return "SignOutEvent.signedOutFailure"
        }
    }

    public init(
        id: String = UUID().uuidString,
        eventType: EventType,
        time: Date? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
}


