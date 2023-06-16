//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public typealias UserSession = String

import Foundation

struct SetUpTOTPEvent: StateMachineEvent {

    enum EventType {

        case setUpTOTP(SignInResponseBehavior)

        case waitForAnswer(SignInTOTPSetupData)

        case verifyChallengeAnswer(ConfirmSignInEventData)

        case respondToAuthChallenge(UserSession)

        case verified

        case throwError(SignInError)

    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {
        case .setUpTOTP: return "SetUpTOTPEvent.setUpTOTP"
        case .verified: return "SetUpTOTPEvent.verified"
        case .verifyChallengeAnswer: return "SetUpTOTPEvent.verifyChallengeAnswer"
        case .waitForAnswer: return "SetUpTOTPEvent.waitForAnswer"
        case .respondToAuthChallenge: return "SetUpTOTPEvent.respondToAuthChallenge"
        case .throwError: return "SetUpTOTPEvent.throwError"
        }
    }

    init(id: String = UUID().uuidString,
         eventType: EventType,
         time: Date? = nil) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
}

extension SetUpTOTPEvent.EventType: Equatable {
    static func == (lhs: SetUpTOTPEvent.EventType, rhs: SetUpTOTPEvent.EventType) -> Bool {
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
