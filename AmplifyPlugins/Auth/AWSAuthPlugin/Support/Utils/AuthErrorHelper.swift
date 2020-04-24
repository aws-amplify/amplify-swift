//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSMobileClient

struct AuthErrorHelper {

    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    static func toAmplifyAuthError(awsMobileClientError: AWSMobileClientError) -> AmplifyAuthError {
        switch awsMobileClientError {

        case .userNotFound(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.userNotFoundError,
                                            AWSCognitoAuthError.userNotFound)

        case .userNotConfirmed(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.userNotConfirmedError,
                                            AWSCognitoAuthError.userNotConfirmed)

        case .usernameExists(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.userNameExistsError,
                                            AWSCognitoAuthError.usernameExists)
        case .aliasExists(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.aliasExistsError,
                                            AWSCognitoAuthError.aliasExists)

        case .codeDeliveryFailure(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.codeDeliveryError,
                                            AWSCognitoAuthError.codeDelivery)

        case .codeMismatch(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.codeMismatchError,
                                            AWSCognitoAuthError.codeMismatch)
        case .expiredCode(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.codeExpiredError,
                                            AWSCognitoAuthError.codeExpired)
        case .invalidLambdaResponse(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.lambdaError,
                                            AWSCognitoAuthError.lambda)

        case .unexpectedLambda(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.lambdaError,
                                            AWSCognitoAuthError.lambda)

        case .userLambdaValidation(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.lambdaError,
                                            AWSCognitoAuthError.lambda)

        case .invalidParameter(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.invalidParameterError,
                                            AWSCognitoAuthError.invalidParameter)

        case .invalidPassword(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.invalidPasswordError,
                                            AWSCognitoAuthError.invalidPassword)

        case .mfaMethodNotFound(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.mfaMethodNotFoundError,
                                            AWSCognitoAuthError.mfaMethodNotFound)

        case .passwordResetRequired(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.passwordResetRequired,
                                            AWSCognitoAuthError.passwordResetRequired)

        case .resourceNotFound(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.resourceNotFoundError,
                                            AWSCognitoAuthError.resourceNotFound)

        case .softwareTokenMFANotFound(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.softwareTokenNotFoundError,
                                            AWSCognitoAuthError.softwareTokenMFANotEnabled)

        case .tooManyFailedAttempts(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.tooManyFailedError,
                                            AWSCognitoAuthError.failedAttemptsLimitExceeded)

        case .tooManyRequests(let message),
             .limitExceeded(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.tooManyRequestError,
                                            AWSCognitoAuthError.requestLimitExceeded)

        case .errorLoadingPage(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.errorLoadingPageError,
                                            AWSCognitoAuthError.errorLoadingUI)

        case .deviceNotRemembered(let message):
            return AmplifyAuthError.service(message,
                                            AuthPluginErrorConstants.deviceNotRememberedError,
                                            AWSCognitoAuthError.deviceNotTracked)

        case .invalidState(let message):
            return AmplifyAuthError.invalidState(message, AuthPluginErrorConstants.invalidStateError)

        case .invalidConfiguration(let message),
             .cognitoIdentityPoolNotConfigured(let message),
             .invalidUserPoolConfiguration(let message):
            return AmplifyAuthError.configuration(message, AuthPluginErrorConstants.configurationError)

        case .notAuthorized(let message):
            // Not authorized is thrown from server when a user is not authorized.
            return AmplifyAuthError.notAuthorized(message, AuthPluginErrorConstants.notAuthorizedError)

        // Below error should not happen, these will be handled inside the plugin.
        case .notSignedIn(let message), // Called in getTokens/getPassword when not signedin to CUP
        .identityIdUnavailable(let message), // From getIdentityId. Handled in plugin
        .guestAccessNotAllowed(let message), // Returned from getAWSCredentials. Handled in plugin
        .federationProviderExists(let message), // User is already signed in to user pool in federatedSignIn
        .unableToSignIn(let message), // Called in signout, releaseSignInWait.
        .idTokenNotIssued(let message), // Not used anywhere.
        // Handled in WebUISignIn inside plugin
        .userPoolNotConfigured(let message):
            // TODO: Hanlde the above errors inside the plugin #172336364
            return AmplifyAuthError.unknown(message)

        case .badRequest(let message),
             .securityFailed(let message),
             .userCancelledSignIn(let message),
             .idTokenAndAcceessTokenNotIssued(let message):
            // These errors are thrown from HostedUI signIn.
            // Handled in WebUISignIn inside plugin.
            return AmplifyAuthError.unknown(message)

        case .expiredRefreshToken(let message):
            // TODO: Should be handled by Auth.fetchSession #172336364
            return AmplifyAuthError.unknown(message)

        // These errors arise from the escape hatch methods.
        case .groupExists(let message),
             .invalidOAuthFlow(let message),
             .scopeDoesNotExist(let message):
            return AmplifyAuthError.unknown(message)

        case .internalError(let message),
             .unknown(let message):
            return AmplifyAuthError.unknown(message)
        }
    }

    static func toAmplifyAuthError(_ error: Error) -> AmplifyAuthError {
        if let awsMobileClientError = error as? AWSMobileClientError {
            return toAmplifyAuthError(awsMobileClientError: awsMobileClientError)
        }
        return AmplifyAuthError.unknown("An unknown error occurred", error)

    }
}
