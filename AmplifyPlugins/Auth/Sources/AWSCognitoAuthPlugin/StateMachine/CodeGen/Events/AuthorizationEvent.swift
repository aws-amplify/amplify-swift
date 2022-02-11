//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct AuthorizationEvent: StateMachineEvent {
    enum EventType: Equatable {

        case configure

        case fetchAuthSession(CognitoCredentials?)

        case fetchedAuthSession(AWSAuthCognitoSession)

        case throwError(AuthorizationError)

    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {
        case .configure: return "AuthorizationEvent.configure"
        case .fetchAuthSession: return "AuthorizationEvent.fetchAuthSession"
        case .fetchedAuthSession: return "AuthorizationEvent.fetchedAuthSession"
        case .throwError: return "AuthorizationEvent.throwError"
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
