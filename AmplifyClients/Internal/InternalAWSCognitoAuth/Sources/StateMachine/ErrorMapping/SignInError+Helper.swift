//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime
import Foundation

package extension SignInError {

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

extension SignInError: EngineAuthErrorConvertible {
    package var engineError: EngineAuthError {
        switch self {
        case .configuration(let message):
            return EngineAuthError.configuration(message, "")
        case .service(let error):
            if let initiateAuthError = error as? EngineAuthErrorConvertible {
                return initiateAuthError.engineError
            } else {
                return EngineAuthError.unknown("", error)
            }
        case .invalidServiceResponse(message: let message):
            return EngineAuthError.service(message, "")
        case .calculation:
            return EngineAuthError.unknown("SignIn calculation returned an error")
        case .inputValidation(let field):
            return EngineAuthError.validation(
                field,
                AuthPluginErrorConstants.signInUsernameError.errorDescription,
                AuthPluginErrorConstants.signInUsernameError.recoverySuggestion
            )
        case .unknown(let message):
            return .unknown(message, nil)
        case .hostedUI(let error):
            return error.engineError
        case .webAuthn(let error):
            return error.engineError
        }
    }
}

extension HostedUIError: EngineAuthErrorConvertible {

    package var engineError: EngineAuthError {
        switch self {
        case .signInURI:
            return .configuration(
                AuthPluginErrorConstants.hostedUISignInURI.errorDescription,
                AuthPluginErrorConstants.hostedUISignInURI.recoverySuggestion
            )

        case .tokenURI:
            return .configuration(
                AuthPluginErrorConstants.hostedUITokenURI.errorDescription,
                AuthPluginErrorConstants.hostedUITokenURI.recoverySuggestion
            )

        case .signOutURI:
            return .configuration(
                AuthPluginErrorConstants.hostedUISignOutURI.errorDescription,
                AuthPluginErrorConstants.hostedUISignOutURI.recoverySuggestion
            )

        case .signOutRedirectURI:
            return .configuration(
                AuthPluginErrorConstants.hostedUISignOutRedirectURI.errorDescription,
                AuthPluginErrorConstants.hostedUISignOutRedirectURI.recoverySuggestion
            )

        case .proofCalculation:
            return .invalidState(
                AuthPluginErrorConstants.hostedUIProofCalculation.errorDescription,
                AuthPluginErrorConstants.hostedUIProofCalculation.recoverySuggestion
            )

        case .codeValidation:
            return .service(
                AuthPluginErrorConstants.hostedUISecurityFailedError.errorDescription,
                AuthPluginErrorConstants.hostedUISecurityFailedError.recoverySuggestion
            )

        case .tokenParsing:
            return .service(
                AuthPluginErrorConstants.tokenParsingError.errorDescription,
                AuthPluginErrorConstants.tokenParsingError.recoverySuggestion
            )

        case .cancelled:
            return .service(
                AuthPluginErrorConstants.hostedUIUserCancelledError.errorDescription,
                AuthPluginErrorConstants.hostedUIUserCancelledError.recoverySuggestion,
                EngineServiceErrorCode.userCancelled
            )

        case .invalidContext:
            return .invalidState(
                AuthPluginErrorConstants.hostedUIInvalidPresentation.errorDescription,
                AuthPluginErrorConstants.hostedUIInvalidPresentation.recoverySuggestion
            )

        case .unableToStartASWebAuthenticationSession:
            return .service(
                AuthPluginErrorConstants.hostedUIUnableToStartASWebAuthenticationSession.errorDescription,
                AuthPluginErrorConstants.hostedUIUnableToStartASWebAuthenticationSession.recoverySuggestion,
                EngineServiceErrorCode.errorLoadingUI
            )

        case .serviceMessage(let message):
            return .service(message, AuthPluginErrorConstants.serviceError)

        case .pluginConfiguration(let message):
            return .configuration(message, AuthPluginErrorConstants.configurationError)

        case .unexpectedIdentity(let mismatch):
            return .service(mismatch.errorDescription, HostedUIIdentityMismatch.recoverySuggestion, mismatch)

        case .unknown:
            return .unknown("WebUI signIn encountered an unknown error", nil)
        }
    }
}
