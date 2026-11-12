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

// Every printed form redacts the session `VerifySoftwareToken` returns, which `CompleteTOTPSetup` answers the MFA
// setup challenge with: `VerifyTOTPSetup` logs the event that carries it at verbose. The other cases read as default
// printing does; their payloads redact their own secrets.
extension SetUpTOTPEvent.EventType: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    package var description: String {
        switch self {
        case .setUpTOTP(let challenge):
            return "setUpTOTP(\(String(reflecting: challenge)))"
        case .waitForAnswer(let setupData):
            return "waitForAnswer(\(String(reflecting: setupData)))"
        case .verifyChallengeAnswer(let answer):
            return "verifyChallengeAnswer(\(String(reflecting: answer)))"
        case .respondToAuthChallenge(let session):
            return "respondToAuthChallenge(\(String(reflecting: session.redactedForLog())))"
        case .verified:
            return "verified"
        case .throwError(let error):
            return "throwError(\(String(reflecting: error)))"
        }
    }

    package var debugDescription: String {
        "\(String(reflecting: Self.self)).\(description)"
    }

    /// For `dump` and debuggers: the session redacted.
    package var customMirror: Mirror {
        switch self {
        case .setUpTOTP(let challenge):
            return Mirror(self, children: ["setUpTOTP": challenge], displayStyle: .enum)
        case .waitForAnswer(let setupData):
            return Mirror(self, children: ["waitForAnswer": setupData], displayStyle: .enum)
        case .verifyChallengeAnswer(let answer):
            return Mirror(self, children: ["verifyChallengeAnswer": answer], displayStyle: .enum)
        case .respondToAuthChallenge(let session):
            return Mirror(self, children: ["respondToAuthChallenge": session.redactedForLog()], displayStyle: .enum)
        case .verified:
            return Mirror(self, children: [:], displayStyle: .enum)
        case .throwError(let error):
            return Mirror(self, children: ["throwError": error], displayStyle: .enum)
        }
    }
}
