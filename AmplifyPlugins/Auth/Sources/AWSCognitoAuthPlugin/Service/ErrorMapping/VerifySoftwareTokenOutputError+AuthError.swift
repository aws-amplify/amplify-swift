//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSCognitoIdentityProvider

extension VerifySoftwareTokenOutputError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .codeMismatchException(let exception):
            return AuthError.service(exception.message ?? "Provided code does not match what the server was expecting.",
                                     AuthPluginErrorConstants.codeMismatchError,
                                     AWSCognitoAuthError.codeMismatch)
        case .enableSoftwareTokenMFAException(let exception):
            return AuthError.service(exception.message ?? "Unable to enable software token MFA",
                                     AuthPluginErrorConstants.serviceError,
                                     AWSCognitoAuthError.softwareTokenMFANotEnabled)
        case .forbiddenException(let forbiddenException):
            return .service(forbiddenException.message ?? "Access to the requested resource is forbidden",
                            AuthPluginErrorConstants.forbiddenError)
        case .internalErrorException(let internalErrorException):
            return .unknown(internalErrorException.message ?? "Internal exception occurred")
        case .invalidParameterException(let invalidParameterException):
            return .service(invalidParameterException.message ?? "Invalid parameter error",
                            AuthPluginErrorConstants.invalidParameterError,
                            AWSCognitoAuthError.invalidParameter)
        case .invalidUserPoolConfigurationException(let exception):
            return .configuration(exception.message ?? "Invalid UserPool Configuration error",
                                  AuthPluginErrorConstants.configurationError)
        case .notAuthorizedException(let notAuthorizedException):
            return .notAuthorized(notAuthorizedException.message ?? "Not authorized Error",
                                  AuthPluginErrorConstants.notAuthorizedError,
                                  nil)
        case .passwordResetRequiredException(let exception):
            return AuthError.service(exception.message ?? "Password reset required error",
                                     AuthPluginErrorConstants.passwordResetRequired,
                                     AWSCognitoAuthError.passwordResetRequired)
        case .resourceNotFoundException(let resourceNotFoundException):
            return AuthError.service(resourceNotFoundException.message ?? "Resource not found error",
                                     AuthPluginErrorConstants.resourceNotFoundError,
                                     AWSCognitoAuthError.resourceNotFound)
        case .softwareTokenMFANotFoundException(let exception):
            return AuthError.service(
                exception.message ?? "Software token TOTP multi-factor authentication (MFA) is not enabled for the user pool.",
                AuthPluginErrorConstants.softwareTokenNotFoundError,
                AWSCognitoAuthError.softwareTokenMFANotEnabled)
        case .tooManyRequestsException(let exception):
            return AuthError.service(exception.message ?? "Too many requests error",
                                     AuthPluginErrorConstants.tooManyRequestError,
                                     AWSCognitoAuthError.requestLimitExceeded)
        case .userNotConfirmedException(let exception):
            return AuthError.service(exception.message ?? "User not confirmed error",
                                     AuthPluginErrorConstants.userNotConfirmedError,
                                     AWSCognitoAuthError.userNotConfirmed)
        case .userNotFoundException(let exception):
            return AuthError.service(exception.message ?? "User not found error",
                                     AuthPluginErrorConstants.userNotFoundError,
                                     AWSCognitoAuthError.userNotFound)
        case .unknown(let unknownAWSHttpServiceError):
            let statusCode = unknownAWSHttpServiceError._statusCode?.rawValue ?? -1
            let message = unknownAWSHttpServiceError._message ?? ""
            return .unknown("Unknown service error occurred with status \(statusCode) \(message)")
        }
    }
}
