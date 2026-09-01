//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation

/// - Note: `@unchecked Sendable`: `StateMachineEvent` requires `Sendable`, but `data` is `Any?`,
///   which the compiler cannot verify. The value stored there is always a `Sendable` payload.
struct SignOutEvent: StateMachineEvent, @unchecked Sendable {
    var data: Any?

    // `Sendable` because the enclosing event conforms to `StateMachineEvent`, which is `Sendable`.
    enum EventType: Sendable {
        case signOutGlobally(
            SignedInData,
            hostedUIError: AWSCognitoHostedUIError? = nil
        )

        case revokeToken(
            SignedInData,
            hostedUIError: AWSCognitoHostedUIError? = nil,
            globalSignOutError: AWSCognitoGlobalSignOutError? = nil
        )

        case signOutLocally(
            SignedInData,
            hostedUIError: AWSCognitoHostedUIError? = nil,
            globalSignOutError: AWSCognitoGlobalSignOutError? = nil,
            revokeTokenError: AWSCognitoRevokeTokenError? = nil
        )

        case signOutGuest

        case invokeHostedUISignOut(SignOutEventData, SignedInData)

        case signedOutSuccess(
            hostedUIError: AWSCognitoHostedUIError? = nil,
            globalSignOutError: AWSCognitoGlobalSignOutError? = nil,
            revokeTokenError: AWSCognitoRevokeTokenError? = nil
        )

        case globalSignOutError(
            SignedInData,
            globalSignOutError: AWSCognitoGlobalSignOutError,
            hostedUIError: AWSCognitoHostedUIError? = nil
        )

        case signedOutFailure(AuthenticationError)

        case hostedUISignOutError(HostedUIError)
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
        case .invokeHostedUISignOut:
            return "SignOutEvent.invokeHostedUISignOut"
        case .signOutLocally:
            return "SignOutEvent.signOutLocally"
        case .signedOutSuccess:
            return "SignOutEvent.signedOutSuccess"
        case .signedOutFailure:
            return "SignOutEvent.signedOutFailure"
        case .globalSignOutError:
            return "SignOutEvent.globalSignOutError"
        case .signOutGuest:
            return "SignOutEvent.signOutGuest"
        case .hostedUISignOutError:
            return "SignOutEvent.hostedUISignOutError"
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

extension SignOutEvent.EventType: Equatable {

    static func == (lhs: SignOutEvent.EventType, rhs: SignOutEvent.EventType) -> Bool {
        switch (lhs, rhs) {
        case (.signOutGlobally, .signOutGlobally),
            (.revokeToken, .revokeToken),
            (.invokeHostedUISignOut, .invokeHostedUISignOut),
            (.signOutLocally, .signOutLocally),
            (.signedOutSuccess, .signedOutSuccess),
            (.signedOutFailure, .signedOutFailure),
            (.globalSignOutError, .globalSignOutError),
            (.signOutGuest, .signOutGuest),
            (.hostedUISignOutError, .hostedUISignOutError):
            return true
        default:
            return false
        }
    }

}
