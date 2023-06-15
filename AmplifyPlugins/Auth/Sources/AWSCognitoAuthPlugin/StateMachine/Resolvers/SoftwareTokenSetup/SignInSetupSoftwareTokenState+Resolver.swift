//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SignInTOTPSetupState {
    struct Resolver: StateMachineResolver {
        typealias StateType = SignInTOTPSetupState
        let defaultState = SignInTOTPSetupState.notStarted

        let signInEventData: SignInEventData

        func resolve(
            oldState: SignInTOTPSetupState,
            byApplying event: StateMachineEvent
        ) -> StateResolution<SignInTOTPSetupState> {

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
            byApplying signInEvent: SetupSoftwareTokenEvent) -> StateResolution<SignInTOTPSetupState> {
                switch signInEvent.eventType {
                case .associateSoftwareToken(let authResponse):
                    let action = AssociateSoftwareToken(
                        authResponse: authResponse)
                    return StateResolution(
                        newState: SignInTOTPSetupState.associateSoftwareToken,
                        actions: [action]
                    )
                default:
                    return .from(.notStarted)
                }
            }

        private func resolveAssociateSoftwareToken(
            byApplying signInEvent: SetupSoftwareTokenEvent) -> StateResolution<SignInTOTPSetupState> {
                switch signInEvent.eventType {
                case .waitForAnswer(let softwareTokenSetupResponse):
                    return StateResolution(
                        newState: SignInTOTPSetupState.waitingForAnswer(softwareTokenSetupResponse),
                        actions: []
                    )
                default:
                    return .from(.notStarted)
                }
            }

        private func resolveWaitForAnswer(
            byApplying signInEvent: SetupSoftwareTokenEvent,
            with associateSoftwareTokenData: AssociateSoftwareTokenData) -> StateResolution<SignInTOTPSetupState> {
                switch signInEvent.eventType {
                case .verifyChallengeAnswer(let confirmSoftwareTokenSetupCode):
                    let action = VerifyTOTPSetup(
                        associateSoftwareTokenData: associateSoftwareTokenData,
                        verifySoftwareTokenUserCode: confirmSoftwareTokenSetupCode.answer)
                    return StateResolution(
                        newState: SignInTOTPSetupState.verifying(associateSoftwareTokenData, confirmSoftwareTokenSetupCode),
                        actions: [action]
                    )
                default:
                    return .from(.notStarted)
                }
            }

        private func resolveVerifyingState(
            byApplying signInEvent: SetupSoftwareTokenEvent,
            with session: String) -> StateResolution<SignInTOTPSetupState> {
                switch signInEvent.eventType {
                case .respondToAuthChallenge(let session):
                    let action = CompleteTOTPSetup(
                        userSession: session,
                        signInEventData: signInEventData)
                    return StateResolution(
                        newState: SignInTOTPSetupState.respondingToAuthChallenge,
                        actions: [action]
                    )
                default:
                    return .from(.notStarted)
                }
            }

        private func errorState(_ error: SignInError)
        -> StateResolution<SignInTOTPSetupState> {
            let action = ThrowSignInError(error: error)
            return StateResolution(
                newState: SignInTOTPSetupState.error(error),
                actions: [action]
            )
        }

    }
}
