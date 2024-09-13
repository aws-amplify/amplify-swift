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

                if case .waitForAnswer(let challenge, let signInMethod, let signInStep) = event.isChallengeEvent {
                    return .init(newState: .waitingForAnswer(challenge, signInMethod, signInStep))
                }
                return .from(oldState)

            case .waitingForAnswer(let challenge, let signInMethod, let signInStep):

                if case .verifyChallengeAnswer(let answerEventData) = event.isChallengeEvent {
                    let action = VerifySignInChallenge(
                        challenge: challenge,
                        confirmSignEventData: answerEventData,
                        signInMethod: signInMethod,
                        currentSignInStep: signInStep)
                    return .init(
                        newState: .verifying(challenge, signInMethod, answerEventData.answer, signInStep),
                        actions: [action]
                    )
                }
                return .from(oldState)

            case .verifying(let challenge, let signInMethod, _, let signInStep):

                if case .retryVerifyChallengeAnswer(let answerEventData, let signInStep) = event.isChallengeEvent {
                    let action = VerifySignInChallenge(
                        challenge: challenge,
                        confirmSignEventData: answerEventData,
                        signInMethod: signInMethod,
                        currentSignInStep: signInStep)
                    return .init(
                        newState: .verifying(challenge, signInMethod, answerEventData.answer, signInStep),
                        actions: [action]
                    )
                }

                if case .finalizeSignIn(let signedInData) = event.isSignInEvent {
                    return .init(newState: .verified,
                                 actions: [SignInComplete(signedInData: signedInData)])
                }

                if case .throwAuthError(let error) = event.isSignInEvent {
                    return .init(newState: .error(challenge, signInMethod, error, signInStep))
                }
                return .from(oldState)

            case .error(let challenge, let signInMethod, _, let signInStep):
                // If a verifyChallengeAnswer is received on error state we allow
                // to retry the challenge.
                if case .verifyChallengeAnswer(let answerEventData) = event.isChallengeEvent {
                    let action = VerifySignInChallenge(
                        challenge: challenge,
                        confirmSignEventData: answerEventData,
                        signInMethod: signInMethod,
                        currentSignInStep: signInStep)
                    return .init(
                        newState: .verifying(challenge, signInMethod, answerEventData.answer, signInStep),
                        actions: [action]
                    )
                }
                return .from(oldState)
            case .verified:

                return .from(oldState)
            }

        }

    }
}
