//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Session value created by the service
package typealias UserSession = String

package struct SetUpTOTPEvent: StateMachineEvent {

    // `Sendable` because the enclosing event conforms to `StateMachineEvent`, which is `Sendable`.
    package enum EventType: Sendable {

        case setUpTOTP(RespondToAuthChallenge)

        case waitForAnswer(SignInTOTPSetupData)

        case verifyChallengeAnswer(ConfirmSignInEventData)

        case respondToAuthChallenge(UserSession)

        case verified

        case throwError(SignInError)

    }

    package let id: String
    package let eventType: EventType
    package let time: Date?

    package var type: String {
        switch eventType {
        case .setUpTOTP: return "SetUpTOTPEvent.setUpTOTP"
        case .verified: return "SetUpTOTPEvent.verified"
        case .verifyChallengeAnswer: return "SetUpTOTPEvent.verifyChallengeAnswer"
        case .waitForAnswer: return "SetUpTOTPEvent.waitForAnswer"
        case .respondToAuthChallenge: return "SetUpTOTPEvent.respondToAuthChallenge"
        case .throwError: return "SetUpTOTPEvent.throwError"
        }
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
}

extension SetUpTOTPEvent.EventType: Equatable {
    package static func == (lhs: SetUpTOTPEvent.EventType, rhs: SetUpTOTPEvent.EventType) -> Bool {
        switch (lhs, rhs) {
        case (.setUpTOTP, .setUpTOTP),
            (.verified, .verified),
            (.verifyChallengeAnswer, .verifyChallengeAnswer),
            (.waitForAnswer, .waitForAnswer),
            (.respondToAuthChallenge, .respondToAuthChallenge),
            (.throwError, .throwError):
            return true
        default:
            return false
        }
    }

}
