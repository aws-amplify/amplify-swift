//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct AuthenticationEvent: StateMachineEvent {
    enum EventType: Equatable {

        /// Emitted at startup when the Authentication system is being initialized
        case configure(AuthConfiguration, CognitoCredentials?)

        /// Emitted at startup when the Authentication system finished configuring
        case configured(AuthConfiguration)

        /// Emitted after configuration, when the system restores persisted state and
        /// resolves the initial state
        case initializedSignedOut(SignedOutData)

        /// Emitted after configuration, when the system restores persisted state and
        /// resolves the initial state
        case initializedSignedIn(SignedInData)

        /// Emitted when a user sign in is requested
        case signInRequested(SignInEventData)

        /// Emitted when a user sign out is requested
        case signOutRequested(SignOutEventData)

        /// Emitted at any time if the Authentication system encounters an error
        case error(AuthenticationError)
    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {
        case .configure:
            return "AuthenticationEvent.configure"
        case .configured:
            return "AuthenticationEvent.configured"
        case .initializedSignedIn:
            return "AuthenticationEvent.initializedSignedIn"
        case .initializedSignedOut:
            return "AuthenticationEvent.initializedSignedOut"
        case .signInRequested:
            return "AuthenticationEvent.signIn"
        case .signOutRequested:
            return "AuthenticationEvent.signOut"
        case .error:
            return "AuthenticationEvent.error"
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
