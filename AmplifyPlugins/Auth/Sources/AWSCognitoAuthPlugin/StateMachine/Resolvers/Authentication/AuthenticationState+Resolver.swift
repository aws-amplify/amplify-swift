//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


extension AuthenticationState {

    struct Resolver: StateMachineResolver {
        typealias StateType = AuthenticationState
        let defaultState = AuthenticationState.notConfigured

        public init() { }

        func resolve(
            oldState: StateType,
            byApplying event: StateMachineEvent
        ) -> StateResolution<StateType> {

            switch oldState {
            case .notConfigured:
                guard let authEvent = event as? AuthenticationEvent else {
                    return .from(oldState)
                }
                return resolveNotConfigured(byApplying: authEvent)
            case .configured(let authConfig):
                guard let authEvent = event as? AuthenticationEvent else {
                    return .from(oldState)
                }
                return resolveConfigured(byApplying: authEvent, to: authConfig)
            case .signedOut(let signedOutData):
                guard let authEvent = event as? AuthenticationEvent else {
                    return .from(oldState)
                }
                return resolveSignedOut(
                    byApplying: authEvent,
                    to: signedOutData,
                    currentConfiguration: signedOutData.authenticationConfiguration
                )
            case .signingIn:
                return resolveSigningInState(oldState: oldState, event: event)
            case .signedIn(let authenticationConfiguration, let signedInData):
                guard let authEvent = event as? AuthenticationEvent else {
                    return .from(oldState)
                }
                return resolveSignedIn(
                    byApplying: authEvent,
                    to: signedInData,
                    currentConfiguration: authenticationConfiguration
                )
            case .error:
                return .from(oldState)
            }
        }

        private func resolveNotConfigured(
            byApplying authEvent: AuthenticationEvent
        ) -> StateResolution<StateType> {

            switch authEvent.eventType {
            case .configure(let authConfig):
                let command = LoadPersistedAuthentication(configuration: authConfig)
                let resolution = StateResolution(
                    newState: AuthenticationState.configured(authConfig),
                    commands: [command]
                )
                return resolution
            default:
                return .from(.notConfigured)
            }
        }

        private func resolveConfigured(
            byApplying authEvent: AuthenticationEvent,
            to currentConfiguration: AuthConfiguration
        ) -> StateResolution<StateType> {
            switch authEvent.eventType {
            case .initializedSignedIn(let signedInData):
                return .from(.signedIn(currentConfiguration, signedInData))
            case .initializedSignedOut(let signedOutData):
                return .from(.signedOut(signedOutData))
            default:
                return .from(.configured(currentConfiguration))
            }
        }

        private func resolveSignedOut(
            byApplying authEvent: AuthenticationEvent,
            to currentSignedOutData: SignedOutData,
            currentConfiguration: AuthConfiguration
        ) -> StateResolution<StateType> {
            switch authEvent.eventType {
            case .signInRequested(let signInData):
                return resolveAuthMethod(
                    for: signInData,
                    currentConfiguration: currentConfiguration,
                    currentSignedOutData: currentSignedOutData
                )
            default:
                return .from(.signedOut(currentSignedOutData))
            }
        }

        private func resolveSignedIn(
            byApplying authEvent: AuthenticationEvent,
            to currentSignedInData: SignedInData,
            currentConfiguration: AuthConfiguration
        ) -> StateResolution<StateType> {
            switch authEvent.eventType {
            case .signOutRequested:
                let signedOutData = SignedOutData(
                    authenticationConfiguration: currentConfiguration,
                    lastKnownUserName: currentSignedInData.userName
                )
                return .from(.signedOut(signedOutData))
            default:
                return .from(.signedIn(currentConfiguration, currentSignedInData))
            }
        }

        /// Resolves the appropriate auth method to use for the incoming sign in event data
        /// and the current configuration.
        ///
        /// TODO: See if this belongs here or in the plugin code. Fix error handling code
        ///
        /// - Parameters:
        ///   - signInData: The SignInEventData for the sign in request
        ///   - currentSignedOutData: The current signed out data, including configuration of
        ///   the Authentication system
        /// - Returns: A StateResolution for the appropriate next step, which may be
        /// signing in with the appropriate method, or resolving to an error if the
        /// configuration and event data is invalid.

        private func resolveAuthMethod(
            for signInData: SignInEventData,
            currentConfiguration: AuthConfiguration,
            currentSignedOutData: SignedOutData
        ) -> StateResolution<StateType> {
            let command = StartSRPFlow(signInEventData: signInData)
            let signInState = SignInState.signingInWithSRP(.notStarted, signInData)
            let resolution = StateResolution(
                newState: AuthenticationState.signingIn(currentConfiguration, signInState),
                commands: [command]
            )
            return resolution
        }

        private func resolveSigningInState(oldState: AuthenticationState,
                                           event: StateMachineEvent) -> StateResolution<StateType>
        {
            guard case .signingIn(let authConfiguration, let signInState) = oldState else {
                return .from(oldState)
            }
            var resolution: StateResolution<StateType>!
            switch signInState {
            case .signingInWithSRP(let srpSignInState, let signInEventData):
                let resolution = SRPSignInState.Resolver().resolve(oldState: srpSignInState, byApplying: event)
                if case .signedIn(let signedInData) = resolution.newState {
                    let newState = AuthenticationState.signedIn(authConfiguration, signedInData)
                    return .init(newState: newState, commands: resolution.commands)
                } else {
                    let signingInWithSRP = SignInState.signingInWithSRP(resolution.newState, signInEventData)
                    let newState = AuthenticationState.signingIn(authConfiguration, signingInWithSRP)
                    return .init(newState: newState, commands: resolution.commands)
                }

            default:
                resolution = .from(oldState)
            }
            return resolution
        }

    }

}
