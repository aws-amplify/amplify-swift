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
            case .waitingForAnswer(let challenge):
                if let signInEvent = event as? SignInEvent {
                    switch signInEvent.eventType {
                    case .verifySMSChallenge(let code):
                        let action = VerifyAuthChallenge(username: challenge.username,
                                                         answer: code,
                                                         session: challenge.session)
                        return .init(newState: .verifying(challenge, code), actions: [action])
                    default:
                        return .from(oldState)
                    }
                }
            case .verifying(let challenge, let answer):
                fatalError()
            default:
                return .from(oldState)
            }

            return .from(oldState)
        }

    }
}
