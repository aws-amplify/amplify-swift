//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct SignInChallengeEvent: StateMachineEvent {

    enum EventType: Equatable {

        case waitForAnswer(RespondToAuthChallenge, SignInMethod, AuthSignInStep)

        case verifyChallengeAnswer(ConfirmSignInEventData)

        case retryVerifyChallengeAnswer(ConfirmSignInEventData, AuthSignInStep)

        case verified

    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {
        case .verified: return "SignInChallengeEvent.verified"
        case .verifyChallengeAnswer: return "SignInChallengeEvent.verifyChallengeAnswer"
        case .waitForAnswer: return "SignInChallengeEvent.waitForAnswer"
        case .retryVerifyChallengeAnswer: return "SignInChallengeEvent.retryVerifyChallengeAnswer"
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
