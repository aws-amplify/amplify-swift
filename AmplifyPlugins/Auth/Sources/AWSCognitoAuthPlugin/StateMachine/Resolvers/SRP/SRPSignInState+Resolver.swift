//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SRPSignInState {
    struct Resolver: StateMachineResolver {
        typealias StateType = SRPSignInState
        let defaultState = SRPSignInState.notStarted

        func resolve(
            oldState: SRPSignInState,
            byApplying event: StateMachineEvent
        ) -> StateResolution<SRPSignInState> {

            guard let srpSignInEvent = event as? SignInEvent else {
                return .from(oldState)
            }

            if case .throwAuthError(let authError) = srpSignInEvent.eventType {
                return errorStateWithCancelSignIn(authError)
            }

            if case .throwPasswordVerifierError(let authError) = srpSignInEvent.eventType {
                return errorStateWithCancelSignIn(authError)
            }

            switch oldState {
            case .notStarted:
                return resolveNotStarted(byApplying: srpSignInEvent)
            case .initiatingSRPA:
                return resolveInitiatingSRPA(byApplying: srpSignInEvent, from: oldState)
            case .respondingPasswordVerifier(let srpStateData):
                return resolveRespondingVerifyPassword(srpStateData: srpStateData, byApplying: srpSignInEvent)
            case .signedIn, .error:
                return .from(oldState)
            case .cancelling:
                return .from(.notStarted)
            }
        }

        private func resolveNotStarted(byApplying signInEvent: SignInEvent) -> StateResolution<SRPSignInState> {
            switch signInEvent.eventType {
            case .initiateSignInWithSRP(let signInEventData):
                guard let username = signInEventData.username, !username.isEmpty else {
                    let error = SignInError.inputValidation(
                        field: AuthPluginErrorConstants.signInUsernameError.field
                    )
                    return errorStateWithCancelSignIn(error)
                }
                let authFlowType: AuthFlowType
                switch signInEventData.signInMethod {
                case .apiBased(let flowType):
                    authFlowType = flowType
                case .unknown:
                    authFlowType = .unknown
                default:
                    let error = SignInError.configuration(message: "Invalid auth flow type during SRP Sign In")
                    return errorStateWithCancelSignIn(error)
                }

                // Assuming password could be nil
                let password = signInEventData.password ?? ""
                let action = InitiateAuthSRP(
                    username: username,
                    password: password,
                    authFlowType: authFlowType,
                    clientMetadata: signInEventData.clientMetadata)
                return StateResolution(
                    newState: SRPSignInState.initiatingSRPA(signInEventData),
                    actions: [action]
                )
            default:
                return .from(.notStarted)
            }
        }

        private func resolveInitiatingSRPA(
            byApplying signInEvent: SignInEvent,
            from oldState: SRPSignInState)
        -> StateResolution<SRPSignInState> {
            switch signInEvent.eventType {
            case .respondPasswordVerifier(let srpStateData, let authResponse):
                let action = VerifyPasswordSRP(stateData: srpStateData,
                                               authResponse: authResponse)
                return StateResolution(
                    newState: SRPSignInState.respondingPasswordVerifier(srpStateData),
                    actions: [action]
                )
            case .cancelSRPSignIn:
                return .from(.cancelling)
            default:
                return .from(oldState)
            }
        }

        private func resolveRespondingVerifyPassword(
            srpStateData: SRPStateData,
            byApplying signInEvent: SignInEvent)
        -> StateResolution<SRPSignInState> {
            switch signInEvent.eventType {
            case .finalizeSignIn(let signedInData):
                return .init(newState: .signedIn(signedInData),
                             actions: [SignInComplete(signedInData: signedInData)])
            case .cancelSRPSignIn:
                return .from(.cancelling)
            default:
                return .from(.respondingPasswordVerifier(srpStateData))
            }
        }

        private func errorStateWithCancelSignIn(_ error: SignInError)
        -> StateResolution<SRPSignInState> {
            let action = CancelSignIn()
            return StateResolution(
                newState: SRPSignInState.error(error),
                actions: [action]
            )
        }

    }
}
