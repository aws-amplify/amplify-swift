//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

enum AuthenticationState: State {
    /// Initial state
    case notConfigured

    /// System is configured, and now knows how to find persisted config data, if any
    case configured

    /// User is signing out
    case signingOut(SignOutState)

    /// System is configured and ready for user to sign in
    case signedOut(SignedOutData)

    /// System is trying to sign up
    case signingUp(SignUpState)

    /// System is trying to sign in
    case signingIn(SignInState)

    /// System is signed in
    case signedIn(SignedInData)
    
    /// System is deleting the user
    case deletingUser(SignedInData, DeleteUserState)

    /// System encountered an error
    case error(AuthenticationError)

}

extension AuthenticationState {

    var type: String {
        switch self {
        case .notConfigured: return "AuthenticationState.notConfigured"
        case .configured: return "AuthenticationState.configured"
        case .signingOut: return "AuthenticationState.signingOut"
        case .signedOut: return "AuthenticationState.signedOut"
        case .signingUp: return "AuthenticationState.signingUp"
        case .signingIn: return "AuthenticationState.signingIn"
        case .signedIn: return "AuthenticationState.signedIn"
        case .deletingUser: return "AuthenticationState.deletingUser"
        case .error: return "AuthenticationState.error"
        }
    }
}
