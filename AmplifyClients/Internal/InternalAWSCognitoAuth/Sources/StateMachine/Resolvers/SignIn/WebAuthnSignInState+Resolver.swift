//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Foundation

package extension WebAuthnSignInState {

    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    struct Resolver: StateMachineResolver {

        package typealias StateType = WebAuthnSignInState
        package let defaultState = WebAuthnSignInState.notStarted

        /// The machine's logger (`AuthState.Resolver.logger`): the retry's factor parse and the assertion's
        /// platform delegate log through it.
        package let logger: any EngineScopedLogger

        package init(logger: any EngineScopedLogger) {
            self.logger = logger
        }

        package func resolve(
            oldState: StateType,
            byApplying event: StateMachineEvent
        )
        -> StateResolution<StateType> {
            if case .error(let error, let challenge) = event.isWebAuthnEvent {
                return .init(
                    newState: .error(.webAuthn(error), challenge)
                )
            }

            switch oldState {
            case .notStarted:
                if case .fetchCredentialOptions(let input) = event.isWebAuthnEvent {
                    let action = FetchCredentialOptions(
                        username: input.username,
                        respondToAuthChallenge: input.challenge,
                        presentationAnchor: input.presentationAnchor
                    )
                    return .init(newState: .fetchingCredentialOptions, actions: [action])
                }
                if case .assertCredentials(let options, let input) = event.isWebAuthnEvent {
                    let action = AssertWebAuthnCredentials(
                        username: input.username,
                        options: options,
                        respondToAuthChallenge: input.challenge,
                        presentationAnchor: input.presentationAnchor,
                        logger: logger
                    )
                    return .init(newState: .assertingCredentials, actions: [action])
                }
            case .fetchingCredentialOptions:
                if case .assertCredentials(let options, let input) = event.isWebAuthnEvent {
                    let action = AssertWebAuthnCredentials(
                        username: input.username,
                        options: options,
                        respondToAuthChallenge: input.challenge,
                        presentationAnchor: input.presentationAnchor,
                        logger: logger
                    )
                    return .init(newState: .assertingCredentials, actions: [action])
                }
            case .assertingCredentials:
                if case .verifyCredentialsAndSignIn(let credentials, let input) = event.isWebAuthnEvent {
                    let action = VerifyWebAuthnCredential(
                        username: input.username,
                        credentials: credentials,
                        respondToAuthChallenge: input.challenge
                    )
                    return .init(
                        newState: .verifyingCredentialsAndSigningIn,
                        actions: [action]
                    )
                }
            case .verifyingCredentialsAndSigningIn:
                if case .signedIn(let signedInData) = event.isWebAuthnEvent {
                    return .init(
                        newState: .signedIn(signedInData),
                        actions: [SignInComplete(signedInData: signedInData)]
                    )
                }
            case .signedIn:
                return .from(oldState)
            case .error(_, let challenge):
                // The WebAuthn flow can be retried on error state when confirming Sign In,
                // so if we receive a new .verifyChallengeAnswer event for WebAuthn, we'll restart the flow
                if case .verifyChallengeAnswer(let data) = event.isChallengeEvent,
                   let authFactorType = EngineAuthFactorType(rawValue: data.answer, logger: logger),
                   case .webAuthn = authFactorType {
                    let action = VerifySignInChallenge(
                        challenge: challenge,
                        confirmSignEventData: data,
                        signInMethod: .apiBased(.userAuth),
                        currentSignInStep: .continueSignInWithFirstFactorSelection([.webAuthn])
                    )
                    return .init(
                        newState: .notStarted,
                        actions: [action]
                    )
                }
            }
            return .from(oldState)
        }
    }
}
#endif
