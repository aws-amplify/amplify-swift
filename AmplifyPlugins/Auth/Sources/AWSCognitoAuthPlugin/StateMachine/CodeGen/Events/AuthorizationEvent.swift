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

        case fetchUnAuthSession

        case cachedCredentialsAvailable(AmplifyCredentials)

        case fetched(IdentityID, AuthAWSCognitoCredentials)

        case sessionEstablished(AmplifyCredentials)

        case throwError(AuthorizationError)

    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {
        case .configure: return "AuthorizationEvent.configure"
        case .sessionEstablished: return "AuthorizationEvent.sessionEstablished"
        case .throwError: return "AuthorizationEvent.throwError"
        case .cachedCredentialsAvailable: return "AuthorizationEvent.cachedCredentialsAvailable"
        case .fetchUnAuthSession: return "AuthorizationEvent.fetchUnAuthSession"
        case .fetched:  return "AuthorizationEvent.fetched"
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
