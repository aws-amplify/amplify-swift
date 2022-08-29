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

        case startFederationToIdentityPool(FederatedToken, IdentityID?)

        case fetchUnAuthSession

        case cachedCredentialsAvailable(AmplifyCredentials)

        case fetched(IdentityID, AuthAWSCognitoCredentials)

        case refreshed(AmplifyCredentials)

        case refreshSession(ForceRefresh)

        case sessionEstablished(AmplifyCredentials)

        case receivedSessionError(FetchSessionError)

        case throwError(AuthorizationError)

    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {
        case .configure: return "AuthorizationEvent.configure"
        case .startFederationToIdentityPool: return "AuthorizationEvent.startFederationToIdentityPool"
        case .refreshed: return "AuthorizationEvent.refreshed"
        case .throwError: return "AuthorizationEvent.throwError"
        case .cachedCredentialsAvailable: return "AuthorizationEvent.cachedCredentialsAvailable"
        case .fetchUnAuthSession: return "AuthorizationEvent.fetchUnAuthSession"
        case .fetched:  return "AuthorizationEvent.fetched"
        case .refreshSession:  return "AuthorizationEvent.refreshSession"
        case .sessionEstablished:  return "AuthorizationEvent.sessionEstablished"
        case .receivedSessionError:  return "AuthorizationEvent.receivedSessionError"
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
