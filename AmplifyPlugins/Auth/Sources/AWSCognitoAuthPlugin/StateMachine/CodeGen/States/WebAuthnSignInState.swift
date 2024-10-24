//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

enum WebAuthnSignInState: State {
    case notStarted
    case fetchingCredentialOptions
    case assertingCredentials
    case verifyingCredentialsAndSigningIn
    case signedIn(SignedInData)
    case cancelled(SignInError)
}

extension WebAuthnSignInState {
    var type: String {
        switch self {
        case .notStarted: return "WebAuthnSignInState.notStarted"
        case .fetchingCredentialOptions: return "WebAuthnSignInState.fetchingCredentialOptions"
        case .assertingCredentials: return "WebAuthnSignInState.assertingCredentialsWithAuthenticator"
        case .verifyingCredentialsAndSigningIn: return "WebAuthnSignInState.verifyingCredentials"
        case .signedIn: return "WebAuthnSignInState.signedIn"
        case .cancelled:  return "WebAuthnSignInState.cancelled"
        }
    }
}

extension WebAuthnSignInState: Equatable { }
