//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import enum Amplify.AuthFactorType
import Foundation

extension WebAuthnSignInState {

    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    struct Resolver: StateMachineResolver {

        typealias StateType = WebAuthnSignInState
        let defaultState = WebAuthnSignInState.notStarted

        func resolve(
            oldState: StateType,
            byApplying event: StateMachineEvent)
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
            case .error(_, let challenge):
                // The WebAuthn flow can be retried on error state when confirming Sign In,
                // so if we receive a new .verifyChallengeAnswer event for WebAuthn, we'll restart the flow
                if case .verifyChallengeAnswer(let data) = event.isChallengeEvent,
                   let authFactorType = AuthFactorType(rawValue: data.answer),
                   case .webAuthn = authFactorType {
                    let action = VerifySignInChallenge(
                        challenge: challenge,
                        confirmSignEventData: data,
                        signInMethod: .apiBased(.userAuth),
                        currentSignInStep: .continueSignInWithFirstFactorSelection([authFactorType])
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
