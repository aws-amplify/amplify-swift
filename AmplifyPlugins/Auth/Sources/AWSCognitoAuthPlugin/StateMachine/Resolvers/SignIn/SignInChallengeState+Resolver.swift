//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

extension SignInChallengeState {

    struct Resolver: StateMachineResolver {

        typealias StateType = SignInChallengeState
        let defaultState = SignInChallengeState.notStarted

        func resolve(
            oldState: SignInChallengeState,
            byApplying event: StateMachineEvent)
        -> StateResolution<SignInChallengeState> {


            switch oldState {
            case .notStarted:
                if case .waitForAnswer(let challenge) = event.isChallengeEvent {
                    return .init(newState: .waitingForAnswer(challenge))
                }
                return .from(oldState)
            case .waitingForAnswer(let response):
                if case .verifyChallengeAnswer(let answer) = event.isChallengeEvent {
                    return .init(newState: .verifying(response, answer))
                }
                return .from(oldState)
            case .verifying(_, _):
                return .from(oldState)
            case .verified:
                return .from(oldState)
            case .error(_):
                return .from(oldState)
            }

        }

    }
}
