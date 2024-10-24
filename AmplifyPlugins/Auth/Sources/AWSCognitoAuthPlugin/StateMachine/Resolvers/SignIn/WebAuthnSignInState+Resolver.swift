//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

extension WebAuthnSignInState {

    @available(iOS 17.4, macOS 13.5, *)
    struct Resolver: StateMachineResolver {

        typealias StateType = WebAuthnSignInState
        let defaultState = WebAuthnSignInState.notStarted

        func resolve(
            oldState: StateType,
            byApplying event: StateMachineEvent)
        -> StateResolution<StateType> {
            if let signInEvent = event as? SignInEvent,
               case .throwAuthError(let error) = signInEvent.eventType {
                return StateResolution(
                    newState: WebAuthnSignInState.cancelled(error)
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
                        presentationAnchor: input.presentationAnchor
                    )
                    return .init(newState: .assertingCredentials, actions: [action])
                }
            case .fetchingCredentialOptions:
                if case .assertCredentials(let options, let input) = event.isWebAuthnEvent {
                    let action = AssertWebAuthnCredentials(
                        username: input.username,
                        options: options,
                        respondToAuthChallenge: input.challenge,
                        presentationAnchor: input.presentationAnchor
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
            case .cancelled(_):
                return .from(oldState)
            }
            return .from(oldState)
        }
    }
}
