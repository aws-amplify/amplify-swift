//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import hierarchical_state_machine_swift

public extension SRPSignInState {
    struct Resolver: StateMachineResolver {
        public typealias StateType = SRPSignInState
        public let defaultState = SRPSignInState.notStarted

        public init() { }

        public func resolve(
            oldState: SRPSignInState,
            byApplying event: StateMachineEvent
        ) -> StateResolution<SRPSignInState> {

            guard let srpSignInEvent = event as? SRPSignInEvent else {
                return .from(oldState)
            }

            if case .throwAuthError(let authError) = srpSignInEvent.eventType {
                return .from(SRPSignInState.error(authError))
            }

            switch oldState {
            case .notStarted:
                return resolveNotStarted(byApplying: srpSignInEvent)
            case .initiatingSRPA:
                return resolveInitiatingSRPA(byApplying: srpSignInEvent, from: oldState)
            case .respondingPasswordVerifier(let srpStateData):
                return resolveRespondingVerifyPassword(srpStateData: srpStateData, byApplying: srpSignInEvent)
            case .nextAuthChallenge:
                return .from(oldState)
            case .signedIn:
                return .from(oldState)
            case .error:
                return .from(oldState)
            case .cancelling:
                return .from(.notStarted)
            }
        }

        private func resolveNotStarted(byApplying signInEvent: SRPSignInEvent) -> StateResolution<SRPSignInState> {
            switch signInEvent.eventType {
            case .initiateSRP(let signInEventData):
                guard let username = signInEventData.username, !username.isEmpty else {
                    let error = SRPSignInError.inputValidation(
                        field: AuthPluginErrorConstants.signInUsernameError.field
                    )
                    return .from(SRPSignInState.error(error))
                }
                // Assuming password could be nil
                let password = signInEventData.password ?? ""
                let command = InitiateAuthSRP(username: username, password: password ?? "")
                return StateResolution(
                    newState: SRPSignInState.initiatingSRPA(signInEventData),
                    commands: [command]
                )
            default:
                return .from(.notStarted)
            }
        }

        private func resolveInitiatingSRPA(byApplying signInEvent: SRPSignInEvent, from oldState: SRPSignInState) -> StateResolution<SRPSignInState> {
            switch signInEvent.eventType {
            case .respondPasswordVerifier(let srpStateData, let authResponse):
                let command = VerifyPasswordSRP(stateData: srpStateData, authResponse: authResponse)
                return StateResolution(
                    newState: SRPSignInState.respondingPasswordVerifier(srpStateData),
                    commands: [command]
                )
            case .throwAuthError(let authError):
                return .from(.error(authError))
            case .cancelSRPSignIn:
                return .from(.cancelling)
            default:
                return .from(oldState)
            }
        }

        private func resolveRespondingVerifyPassword(srpStateData: SRPStateData,
                                                     byApplying signInEvent: SRPSignInEvent)  -> StateResolution<SRPSignInState>
        {
            switch signInEvent.eventType {
            case .finalizeSRPSignIn(let signedInData):
                return .from(.signedIn(signedInData))
            case .respondNextAuthChallenge(let authChallengeResponse):
                return .from(.nextAuthChallenge(authChallengeResponse))
            case .throwPasswordVerifierError(let authError):
                return .from(.error(authError))
            case .cancelSRPSignIn:
                return .from(.cancelling)
            default:
                return .from(.respondingPasswordVerifier(srpStateData))
            }
        }

    }
}
