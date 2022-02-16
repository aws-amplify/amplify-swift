//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension SignUpError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .invalidState(message: let message):
            fatalError("Fix me \(message)")
        case .invalidUsername:
            return AuthError.validation(
                AuthPluginErrorConstants.signUpUsernameError.field,
                AuthPluginErrorConstants.signUpUsernameError.errorDescription,
                AuthPluginErrorConstants.signUpUsernameError.recoverySuggestion, nil)
        case .invalidPassword:
            return AuthError.validation(
                AuthPluginErrorConstants.signUpPasswordError.field,
                AuthPluginErrorConstants.signUpPasswordError.errorDescription,
                AuthPluginErrorConstants.signUpPasswordError.recoverySuggestion, nil)
        case .invalidConfirmationCode(message: let message):
            fatalError("Fix me \(message)")
        case .service(error: let error):
            if let initiateAuthError = error as? AuthErrorConvertible {
                return initiateAuthError.authError
            } else {
                return AuthError.unknown("Received unknown error from service", error)
            }
        }
    }
}
