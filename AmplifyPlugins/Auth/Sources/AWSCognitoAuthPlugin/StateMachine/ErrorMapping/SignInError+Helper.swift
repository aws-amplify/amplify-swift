//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import ClientRuntime
import AWSCognitoIdentityProvider

extension SignInError {

    var isUserNotConfirmed: Bool {
        switch self {
        case .service(error: let serviceError):
            return serviceError is AWSCognitoIdentityProvider.UserNotConfirmedException
        default:
            return false
        }
    }

    var isResetPassword: Bool {
        switch self {
        case .service(error: let serviceError):
            return serviceError is AWSCognitoIdentityProvider.PasswordResetRequiredException
        default:
            return false
        }
    }
}

extension SignInError: AuthErrorConvertible {
    var fallbackDescription: String { "" }

    var authError: AuthError {
        switch self {
        case .configuration(let message):
            return AuthError.configuration(message, "")
        case .service(let error):
            if let initiateAuthError = error as? AuthErrorConvertible {
                return initiateAuthError.authError
            } else {
                return AuthError.unknown("", error)
            }
        case .invalidServiceResponse(message: let message):
            return AuthError.service(message, "")
        case .calculation:
            return AuthError.unknown("SignIn calculation returned an error")
        case .inputValidation(let field):
            return AuthError.validation(
                field,
                AuthPluginErrorConstants.signInUsernameError.errorDescription,
                AuthPluginErrorConstants.signInUsernameError.recoverySuggestion)
        case .unknown(let message):
            return .unknown(message, nil)
        case .hostedUI(let error):
            return error.authError
        }
    }
}

extension HostedUIError: AuthErrorConvertible {
    var fallbackDescription: String { "" }

    var authError: AuthError {
        switch self {
        case .signInURI:
            return .configuration(
                AuthPluginErrorConstants.hostedUISignInURI.errorDescription,
                AuthPluginErrorConstants.hostedUISignInURI.recoverySuggestion)

        case .tokenURI:
            return .configuration(
                AuthPluginErrorConstants.hostedUITokenURI.errorDescription,
                AuthPluginErrorConstants.hostedUITokenURI.recoverySuggestion)

        case .signOutURI:
            return .service(
                AuthPluginErrorConstants.hostedUISignOutURI.errorDescription,
                AuthPluginErrorConstants.hostedUISignOutURI.recoverySuggestion)

        case .proofCalculation:
            return .invalidState(
                AuthPluginErrorConstants.hostedUIProofCalculation.errorDescription,
                AuthPluginErrorConstants.hostedUIProofCalculation.recoverySuggestion)

        case .codeValidation:
            return .service(
                AuthPluginErrorConstants.hostedUISecurityFailedError.errorDescription,
                AuthPluginErrorConstants.hostedUISecurityFailedError.recoverySuggestion)

        case .tokenParsing:
            return .service(
                AuthPluginErrorConstants.tokenParsingError.errorDescription,
                AuthPluginErrorConstants.tokenParsingError.recoverySuggestion)

        case .cancelled:
            return .service(
                AuthPluginErrorConstants.hostedUIUserCancelledError.errorDescription,
                AuthPluginErrorConstants.hostedUIUserCancelledError.recoverySuggestion,
                AWSCognitoAuthError.userCancelled)

        case .invalidContext:
            return .invalidState(
                AuthPluginErrorConstants.hostedUIInvalidPresentation.errorDescription,
                AuthPluginErrorConstants.hostedUIInvalidPresentation.recoverySuggestion)

        case .serviceMessage(let message):
            return .service(message, AuthPluginErrorConstants.serviceError)

        case .unknown:
            return .unknown("WebUI signIn encountered an unknown error", nil)

        }
    }
}
