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

            case .waitingForAnswer(let challenge):

                if case .verifyChallengeAnswer(let answer) = event.isChallengeEvent {
                    let action = VerifySignInChallenge(challenge: challenge, answer: answer)
                    return .init(newState: .verifying(challenge, answer), actions: [action])
                }
                return .from(oldState)

            case .verifying(let challenge, _):

                if case .finalizeSignIn(let signedInData) = event.isSignInEvent {
                    return .init(newState: .verified,
                                 actions: [SignInComplete(signedInData: signedInData)])
                }

                if case .throwAuthError(let error) = event.isSignInEvent {
                    return .init(newState: .error(challenge, error))
                }
                return .from(oldState)

            case .verified, .error:

                return .from(oldState)
            }

        }

    }
}
