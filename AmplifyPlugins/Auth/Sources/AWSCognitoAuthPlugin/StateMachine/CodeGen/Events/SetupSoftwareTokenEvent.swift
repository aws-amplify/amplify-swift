//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public typealias UserSession = String

import Foundation

struct SetupSoftwareTokenEvent: StateMachineEvent {

    enum EventType {

        case associateSoftwareToken(SignInResponseBehavior)

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
        case .associateSoftwareToken: return "SetupSoftwareTokenEvent.associateSoftwareToken"
        case .verified: return "SetupSoftwareTokenEvent.verified"
        case .verifyChallengeAnswer: return "SetupSoftwareTokenEvent.verifyChallengeAnswer"
        case .waitForAnswer: return "SetupSoftwareTokenEvent.waitForAnswer"
        case .respondToAuthChallenge: return "SetupSoftwareTokenEvent.respondToAuthChallenge"
        case .throwError: return "SetupSoftwareTokenEvent.throwError"
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

extension SetupSoftwareTokenEvent.EventType: Equatable {
    static func == (lhs: SetupSoftwareTokenEvent.EventType, rhs: SetupSoftwareTokenEvent.EventType) -> Bool {
        switch (lhs, rhs) {
        case (.associateSoftwareToken, .associateSoftwareToken),
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
