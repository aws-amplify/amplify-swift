//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SignInSetupSoftwareTokenState {
    struct Resolver: StateMachineResolver {
        typealias StateType = SignInSetupSoftwareTokenState
        let defaultState = SignInSetupSoftwareTokenState.notStarted

        let signInEventData: SignInEventData

        func resolve(
            oldState: SignInSetupSoftwareTokenState,
            byApplying event: StateMachineEvent
        ) -> StateResolution<SignInSetupSoftwareTokenState> {

            guard let setupSoftwareTokenEvent = event as? SetupSoftwareTokenEvent else {
                return .from(oldState)
            }

            if case .throwError(let authError) = setupSoftwareTokenEvent.eventType {
                return errorState(authError)
            }

            switch oldState {
            case .notStarted:
                return resolveNotStarted(byApplying: setupSoftwareTokenEvent)
            case .associateSoftwareToken:
                return resolveAssociateSoftwareToken(byApplying: setupSoftwareTokenEvent)
            case .waitingForAnswer(let associateSoftwareTokenData):
                return resolveWaitForAnswer(
                    byApplying: setupSoftwareTokenEvent,
                    with: associateSoftwareTokenData)
            case .verifying(let tokenData, _):
                return resolveVerifyingState(
                    byApplying: setupSoftwareTokenEvent, with: tokenData.session)
            default:
                fatalError("TODO")
            }
        }

        private func resolveNotStarted(
            byApplying signInEvent: SetupSoftwareTokenEvent) -> StateResolution<SignInSetupSoftwareTokenState> {
                switch signInEvent.eventType {
                case .associateSoftwareToken(let authResponse):
                    let action = AssociateSoftwareToken(
                        authResponse: authResponse)
                    return StateResolution(
                        newState: SignInSetupSoftwareTokenState.associateSoftwareToken,
                        actions: [action]
                    )
                default:
                    return .from(.notStarted)
                }
            }

        private func resolveAssociateSoftwareToken(
            byApplying signInEvent: SetupSoftwareTokenEvent) -> StateResolution<SignInSetupSoftwareTokenState> {
                switch signInEvent.eventType {
                case .waitForAnswer(let softwareTokenSetupResponse):
                    return StateResolution(
                        newState: SignInSetupSoftwareTokenState.waitingForAnswer(softwareTokenSetupResponse),
                        actions: []
                    )
                default:
                    return .from(.notStarted)
                }
            }

        private func resolveWaitForAnswer(
            byApplying signInEvent: SetupSoftwareTokenEvent,
            with associateSoftwareTokenData: AssociateSoftwareTokenData) -> StateResolution<SignInSetupSoftwareTokenState> {
                switch signInEvent.eventType {
                case .verifyChallengeAnswer(let confirmSoftwareTokenSetupCode):
                    let action = VerifySoftwareTokenSetup(
                        associateSoftwareTokenData: associateSoftwareTokenData,
                        verifySoftwareTokenUserCode: confirmSoftwareTokenSetupCode.answer)
                    return StateResolution(
                        newState: SignInSetupSoftwareTokenState.verifying(associateSoftwareTokenData, confirmSoftwareTokenSetupCode),
                        actions: [action]
                    )
                default:
                    return .from(.notStarted)
                }
            }

        private func resolveVerifyingState(
            byApplying signInEvent: SetupSoftwareTokenEvent,
            with session: String) -> StateResolution<SignInSetupSoftwareTokenState> {
                switch signInEvent.eventType {
                case .respondToAuthChallenge(let session):
                    let action = CompleteSoftwareTokenSetup(
                        userSession: session,
                        signInEventData: signInEventData)
                    return StateResolution(
                        newState: SignInSetupSoftwareTokenState.respondingToAuthChallenge,
                        actions: [action]
                    )
                default:
                    return .from(.notStarted)
                }
            }

        private func errorState(_ error: SignInError)
        -> StateResolution<SignInSetupSoftwareTokenState> {
            let action = ThrowSignInError(error: error)
            return StateResolution(
                newState: SignInSetupSoftwareTokenState.error(error),
                actions: [action]
            )
        }

    }
}
