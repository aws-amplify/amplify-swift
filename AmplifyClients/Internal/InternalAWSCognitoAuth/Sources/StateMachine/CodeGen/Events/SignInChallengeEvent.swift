//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct SignInChallengeEvent: StateMachineEvent {

    // `Sendable` because the enclosing event conforms to `StateMachineEvent`, which is `Sendable`.
    package enum EventType: Equatable, Sendable {

        case waitForAnswer(RespondToAuthChallenge, SignInMethod, EngineSignInStep)

        case verifyChallengeAnswer(ConfirmSignInEventData)

        case retryVerifyChallengeAnswer(ConfirmSignInEventData, EngineSignInStep)

        case verified

    }

    package let id: String
    package let eventType: EventType
    package let time: Date?

    package var type: String {
        switch eventType {
        case .verified: return "SignInChallengeEvent.verified"
        case .verifyChallengeAnswer: return "SignInChallengeEvent.verifyChallengeAnswer"
        case .waitForAnswer: return "SignInChallengeEvent.waitForAnswer"
        case .retryVerifyChallengeAnswer: return "SignInChallengeEvent.retryVerifyChallengeAnswer"
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
