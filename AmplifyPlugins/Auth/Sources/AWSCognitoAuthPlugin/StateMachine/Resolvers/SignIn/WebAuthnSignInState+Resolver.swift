//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

extension WebAuthnSignInState {

    struct Resolver: StateMachineResolver {

        typealias StateType = WebAuthnSignInState
        let defaultState = WebAuthnSignInState.notStarted

        func resolve(
            oldState: StateType,
            byApplying event: StateMachineEvent)
        -> StateResolution<StateType> {

            if case .throwError(let signInError) = event.isWebAuthnEvent {
                return .init(newState: .error(signInError), actions: [])
            }

            switch oldState {

            case .notStarted:
                if case .fetchCredentialOptions = event.isWebAuthnEvent {
                    let action = FetchCredentialOptions()
                    return .init(newState: .fetchingCredentialOptions, actions: [action])
                }
                if case .assertCredentials = event.isWebAuthnEvent {
                    let action = AssertWebAuthnCredentials()
                    return .init(newState: .assertingCredentials, actions: [action])
                }
            case .fetchingCredentialOptions:
                if case .assertCredentials = event.isWebAuthnEvent {
                    let action = AssertWebAuthnCredentials()
                    return .init(newState: .assertingCredentials, actions: [action])
                }
            case .assertingCredentials:
                if case .verifyCredentialsAndSignIn = event.isWebAuthnEvent {
                    let action = VerifyWebAuthnCredential()
                    return .init(newState: .verifyingCredentialsAndSigningIn, actions: [action])
                }
                if case .cancel = event.isWebAuthnEvent {
                    let action = CancelSignIn()
                    return .init(newState: .cancelled, actions: [action])
                }
            case .verifyingCredentialsAndSigningIn:
                if case .signedIn = event.isWebAuthnEvent {
                    fatalError("uncomment state machine resolution to complete sign in")
//                    return .init(newState: .signedIn(signedInData),
//                                 actions: [SignInComplete(signedInData: signedInData)])
                }
            case .signedIn(_):
                // Signed in.. don't do anything
                return .from(oldState)
            case .error(_):
                // TOOD: figure out if the state is retryable
                return .from(oldState)
            case .cancelled:
                return .from(oldState)
            }
            return .from(oldState)
        }
    }
}
