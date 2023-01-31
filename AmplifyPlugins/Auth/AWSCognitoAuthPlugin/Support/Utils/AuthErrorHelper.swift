//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import SafariServices
import AuthenticationServices
#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

struct AuthErrorHelper {

    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    static func toAuthError(awsMobileClientError: AWSMobileClientError) -> AuthError {
        switch awsMobileClientError {

        case .userNotFound(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.userNotFoundError,
                                            AWSCognitoAuthError.userNotFound)

        case .userNotConfirmed(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.userNotConfirmedError,
                                            AWSCognitoAuthError.userNotConfirmed)

        case .usernameExists(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.userNameExistsError,
                                            AWSCognitoAuthError.usernameExists)
        case .aliasExists(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.aliasExistsError,
                                            AWSCognitoAuthError.aliasExists)

        case .codeDeliveryFailure(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.codeDeliveryError,
                                            AWSCognitoAuthError.codeDelivery)

        case .codeMismatch(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.codeMismatchError,
                                            AWSCognitoAuthError.codeMismatch)
        case .expiredCode(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.codeExpiredError,
                                            AWSCognitoAuthError.codeExpired)
        case .invalidLambdaResponse(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.lambdaError,
                                            AWSCognitoAuthError.lambda)

        case .unexpectedLambda(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.lambdaError,
                                            AWSCognitoAuthError.lambda)

        case .userLambdaValidation(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.lambdaError,
                                            AWSCognitoAuthError.lambda)

        case .invalidParameter(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.invalidParameterError,
                                            AWSCognitoAuthError.invalidParameter)

        case .invalidPassword(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.invalidPasswordError,
                                            AWSCognitoAuthError.invalidPassword)

        case .mfaMethodNotFound(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.mfaMethodNotFoundError,
                                            AWSCognitoAuthError.mfaMethodNotFound)

        case .passwordResetRequired(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.passwordResetRequired,
                                            AWSCognitoAuthError.passwordResetRequired)

        case .resourceNotFound(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.resourceNotFoundError,
                                            AWSCognitoAuthError.resourceNotFound)

        case .softwareTokenMFANotFound(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.softwareTokenNotFoundError,
                                            AWSCognitoAuthError.softwareTokenMFANotEnabled)

        case .tooManyFailedAttempts(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.tooManyFailedError,
                                            AWSCognitoAuthError.failedAttemptsLimitExceeded)

        case .tooManyRequests(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.tooManyRequestError,
                                            AWSCognitoAuthError.requestLimitExceeded)

        case .limitExceeded(let message):
            return AuthError.service(message,
                                     AuthPluginErrorConstants.limitExceededError,
                                     AWSCognitoAuthError.limitExceeded)

        case .errorLoadingPage(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.errorLoadingPageError,
                                            AWSCognitoAuthError.errorLoadingUI)

        case .deviceNotRemembered(let message):
            return AuthError.service(message,
                                            AuthPluginErrorConstants.deviceNotRememberedError,
                                            AWSCognitoAuthError.deviceNotTracked)

        case .invalidState(let message):
            return AuthError.invalidState(message, AuthPluginErrorConstants.invalidStateError)

        case .invalidConfiguration(let message),
             .cognitoIdentityPoolNotConfigured(let message),
             .invalidUserPoolConfiguration(let message):
            return AuthError.configuration(message, AuthPluginErrorConstants.configurationError)

        case .notAuthorized(let message):
            // Not authorized is thrown from server when a user is not authorized.
            return AuthError.notAuthorized(message, AuthPluginErrorConstants.notAuthorizedError)

        // Below error should not happen, these will be handled inside the plugin.
        case .notSignedIn(let message), // Occurs in deleteUser,getTokens,getPassword when not signedin to CUP.
        .identityIdUnavailable(let message), // From getIdentityId. Handled in plugin
        .guestAccessNotAllowed(let message), // Returned from getAWSCredentials. Handled in plugin
        .federationProviderExists(let message), // User is already signed in to user pool in federatedSignIn
        .unableToSignIn(let message), // Called in signout, releaseSignInWait.
        .idTokenNotIssued(let message), // Not used anywhere.
        .userPoolNotConfigured(let message):
            return AuthError.unknown(message)

        case .badRequest(let message),
             .securityFailed(let message),
             .userCancelledSignIn(let message),
             .idTokenAndAcceessTokenNotIssued(let message):
            // These errors are thrown from HostedUI signIn.
            // Handled in WebUISignIn inside plugin.
            return AuthError.unknown(message)

        case .expiredRefreshToken(let message):
            return AuthError.unknown(message)

        // These errors arise from the escape hatch methods.
        case .groupExists(let message),
             .invalidOAuthFlow(let message),
             .scopeDoesNotExist(let message):
            return AuthError.unknown(message)

        case .internalError(let message),
             .unknown(let message):
            return AuthError.unknown(message)
        @unknown default:
            return AuthError.unknown("An unknown error occurred", awsMobileClientError)
        }
    }

    static func toAuthError(_ error: Error) -> AuthError {
        if let awsMobileClientError = error as? AWSMobileClientError {
            return toAuthError(awsMobileClientError: awsMobileClientError)
        } else if let authError = error as? AuthError {
            return authError
        }
        return AuthError.unknown("An unknown error occurred", error)

    }

    static func didUserCancelHostedUI(_ error: Error) -> Bool {
        if let sfAuthError = error as? SFAuthenticationError,
           case SFAuthenticationError.Code.canceledLogin = sfAuthError.code {
            return true
        }

        if #available(iOS 12.0, *) {

            if let asWebAuthError = error as? ASWebAuthenticationSessionError,
               case ASWebAuthenticationSessionError.Code.canceledLogin = asWebAuthError.code {
                return true
            }
        }

        return false
    }
}
