//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation

package typealias ConfirmationCode = String
package typealias ForceAliasCreation = Bool
package struct SignUpEvent: StateMachineEvent {
    package var id: String
    package var time: Date?
    package let eventType: EventType

    // `Sendable` because the enclosing event conforms to `StateMachineEvent`, which is `Sendable`.
    package enum EventType: Sendable {
        case initiateSignUp(SignUpEventData, Password?, [EngineUserAttribute]?)
        case initiateSignUpComplete(SignUpEventData, EngineSignUpResult)
        case confirmSignUp(SignUpEventData, ConfirmationCode, ForceAliasCreation?)
        case signedUp(SignUpEventData, EngineSignUpResult)
        case throwAuthError(SignUpError, SignUpEventData)
    }

    package init(
        id: String = UUID().uuidString,
        eventType: EventType,
        time: Date? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }

    package var type: String {
        switch eventType {
        case .initiateSignUp: return "SignUpEvent.initiateSignUp"
        case .initiateSignUpComplete: return "SignUpEvent.initiateSignUpComplete"
        case .confirmSignUp: return "SignUpEvent.confirmSignUp"
        case .signedUp: return "SignUpEvent.signedUp"
        case .throwAuthError: return "SignUpEvent.throwAuthError"
        }
    }

}
