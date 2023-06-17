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

            guard let setupTOTPEvent = event as? SetUpTOTPEvent else {
                return .from(oldState)
            }

            switch oldState {
            case .notStarted:
                return resolveNotStarted(byApplying: setupTOTPEvent)
            case .setUpTOTP:
                return resolveSetUpTOTPState(byApplying: setupTOTPEvent)
            case .waitingForAnswer(let signInTOTPSetupData):
                return resolveWaitForAnswer(
                    byApplying: setupTOTPEvent,
                    with: signInTOTPSetupData)
            case .verifying(let signInTOTPSetupData, _):
                return resolveVerifyingState(
                    byApplying: setupTOTPEvent, with: signInTOTPSetupData)
            case .error(let signInTOTPSetupData, _):
                return resolveErrorState(byApplying: setupTOTPEvent,
                                         with: signInTOTPSetupData)
            default:
                return .from(.notStarted)
            }
        }

        private func resolveNotStarted(
            byApplying signInEvent: SetUpTOTPEvent) -> StateResolution<SignInTOTPSetupState> {
                switch signInEvent.eventType {
                case .setUpTOTP(let authResponse):
                    let action = SetUpTOTP(
                        authResponse: authResponse,
                        signInEventData: signInEventData)
                    return StateResolution(
                        newState: SignInTOTPSetupState.setUpTOTP,
                        actions: [action]
                    )
                case .throwError(let error):
                    return .init(newState: .error(nil, error))
                default:
                    return .from(.notStarted)
                }
            }

        private func resolveSetUpTOTPState(
            byApplying signInEvent: SetUpTOTPEvent) -> StateResolution<SignInTOTPSetupState> {
                switch signInEvent.eventType {
                case .waitForAnswer(let totpSetupResponse):
                    return StateResolution(
                        newState: SignInTOTPSetupState.waitingForAnswer(totpSetupResponse),
                        actions: []
                    )
                default:
                    return .from(.notStarted)
                }
            }

        private func resolveWaitForAnswer(
            byApplying signInEvent: SetUpTOTPEvent,
            with signInTOTPSetupData: SignInTOTPSetupData) -> StateResolution<SignInTOTPSetupState> {
                switch signInEvent.eventType {
                case .verifyChallengeAnswer(let confirmSignInEventData):
                    let action = VerifyTOTPSetup(
                        session: signInTOTPSetupData.session,
                        totpCode: confirmSignInEventData.answer,
                        friendlyDeviceName: confirmSignInEventData.friendlyDeviceName)
                    return StateResolution(
                        newState: SignInTOTPSetupState.verifying(
                            signInTOTPSetupData,
                            confirmSignInEventData),
                        actions: [action]
                    )
                case .throwError(let error):
                    return .init(newState: .error(signInTOTPSetupData, error))
                default:
                    return .from(.notStarted)
                }
            }

        private func resolveVerifyingState(
            byApplying signInEvent: SetUpTOTPEvent,
            with signInTOTPSetupData: SignInTOTPSetupData) -> StateResolution<SignInTOTPSetupState> {
                switch signInEvent.eventType {
                case .respondToAuthChallenge(let session):
                    let action = CompleteTOTPSetup(
                        userSession: session,
                        signInEventData: signInEventData)
                    return StateResolution(
                        newState: SignInTOTPSetupState.respondingToAuthChallenge,
                        actions: [action]
                    )
                case .throwError(let error):
                    return .init(newState: .error(signInTOTPSetupData, error))
                default:
                    return .from(.notStarted)
                }
            }

        private func resolveErrorState(
            byApplying signInEvent: SetUpTOTPEvent,
            with signInTOTPSetupData: SignInTOTPSetupData?) -> StateResolution<SignInTOTPSetupState> {

                switch signInEvent.eventType {
                case .verifyChallengeAnswer(let confirmSignInEventData):
                    guard let signInTOTPSetupData = signInTOTPSetupData else {
                        return .from(.notStarted)
                    }
                    let action = VerifyTOTPSetup(
                        session: signInTOTPSetupData.session,
                        totpCode: confirmSignInEventData.answer,
                        friendlyDeviceName: confirmSignInEventData.friendlyDeviceName)
                    return StateResolution(
                        newState: SignInTOTPSetupState.verifying(
                            signInTOTPSetupData,
                            confirmSignInEventData),
                        actions: [action]
                    )
                default:
                    return .from(.notStarted)
                }
            }

    }
}
