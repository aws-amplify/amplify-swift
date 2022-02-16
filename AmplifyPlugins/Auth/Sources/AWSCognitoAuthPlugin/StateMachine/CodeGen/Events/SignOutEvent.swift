//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider

struct SignOutEvent: StateMachineEvent {
    var data: Any?

    enum EventType: Equatable {
        static func == (lhs: SignOutEvent.EventType, rhs: SignOutEvent.EventType) -> Bool {
            return false
        }

        case signOutGlobally(SignedInData)
        case revokeToken(SignedInData)
        case signOutLocally(SignedInData)
        case signedOutSuccess
        case signedOutFailure(AuthenticationError)
    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
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

    init(
        id: String = UUID().uuidString,
        eventType: EventType,
        time: Date? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
}


