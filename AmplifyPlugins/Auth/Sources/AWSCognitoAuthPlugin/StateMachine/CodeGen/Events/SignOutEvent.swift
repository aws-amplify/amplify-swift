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

    enum EventType {
        case signOutGlobally(
            SignedInData,
            hostedUIError: AWSCognitoHostedUIError? = nil)

        case revokeToken(
            SignedInData,
            hostedUIError: AWSCognitoHostedUIError? = nil,
            globalSignOutError: AWSCognitoGlobalSignOutError? = nil)

        case signOutLocally(
            SignedInData,
            hostedUIError: AWSCognitoHostedUIError? = nil,
            globalSignOutError: AWSCognitoGlobalSignOutError? = nil,
            revokeTokenError: AWSCognitoRevokeTokenError? = nil)
        
        case signOutGuest

        case invokeHostedUISignOut(SignOutEventData, SignedInData)

        case signedOutSuccess(hostedUIError: AWSCognitoHostedUIError? = nil,
                              globalSignOutError: AWSCognitoGlobalSignOutError? = nil,
                              revokeTokenError: AWSCognitoRevokeTokenError? = nil)

        case globalSignOutError(SignedInData,
                                globalSignOutError: AWSCognitoGlobalSignOutError,
                                hostedUIError: AWSCognitoHostedUIError? = nil)

        case signedOutFailure(AuthenticationError)

        case userCancelled
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
        case .userCancelled:
            return "SignOutEvent.userCancelled"
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
            (.userCancelled, .userCancelled):
            return true
        default:
            return false
        }
    }

}
