//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
import Amplify

extension ConfirmForgotPasswordOutputError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .codeMismatchException(let exception):
            return AuthError.service(exception.message ?? "Provided code does not match what the server was expecting.",
                                     AuthPluginErrorConstants.codeMismatchError,
                                     AWSCognitoAuthError.codeMismatch)
        case .expiredCodeException(let exception):
            return AuthError.service(exception.message ?? "Provided code has expired.",
                                     AuthPluginErrorConstants.codeExpiredError,
                                     AWSCognitoAuthError.codeExpired)
        case .internalErrorException(let exception):
            return .unknown(exception.message ?? "Internal exception occurred")
        case .invalidLambdaResponseException(let exception):
            return .service(exception.message ?? "Invalid lambda response error",
                            AuthPluginErrorConstants.lambdaError,
                            AWSCognitoAuthError.lambda)
        case .invalidParameterException(let exception):
            return AuthError.service(exception.message ?? "Invalid parameter error",
                                     AuthPluginErrorConstants.invalidParameterError,
                                     AWSCognitoAuthError.invalidParameter)
        case .invalidPasswordException(let exception):
            return AuthError.service(exception.message ?? "Invalid password error",
                                     AuthPluginErrorConstants.invalidPasswordError,
                                     AWSCognitoAuthError.invalidPassword)
        case .limitExceededException(let exception):
            return .service(exception.message ?? "Limit exceeded error",
                            AuthPluginErrorConstants.limitExceededError,
                            AWSCognitoAuthError.limitExceeded)
        case .notAuthorizedException(let exception):
            return AuthError.notAuthorized(exception.message ?? "Not authorized error",
                                           AuthPluginErrorConstants.notAuthorizedError)
        case .resourceNotFoundException(let exception):
            return AuthError.service(exception.message ?? "Resource not found error",
                                     AuthPluginErrorConstants.resourceNotFoundError,
                                     AWSCognitoAuthError.resourceNotFound)
        case .tooManyFailedAttemptsException(let exception):
            return AuthError.service(exception.message ?? "Too many failed attempts error",
                                     AuthPluginErrorConstants.tooManyFailedError,
                                     AWSCognitoAuthError.failedAttemptsLimitExceeded)
        case .tooManyRequestsException(let exception):
            return AuthError.service(exception.message ?? "Too many requests error",
                                     AuthPluginErrorConstants.tooManyRequestError,
                                     AWSCognitoAuthError.requestLimitExceeded)
        case .unexpectedLambdaException(let exception):
            return .service(exception.message ?? "Unexpected lambda error",
                            AuthPluginErrorConstants.lambdaError,
                            AWSCognitoAuthError.lambda)
        case .userLambdaValidationException(let exception):
            return .service(exception.message ?? "User lambda validation error",
                            AuthPluginErrorConstants.lambdaError,
                            AWSCognitoAuthError.lambda)
        case .userNotConfirmedException(let userNotConfirmedException):
            return .service(userNotConfirmedException.message ?? "User not confirmed error",
                            AuthPluginErrorConstants.userNotConfirmedError,
                            AWSCognitoAuthError.userNotConfirmed)
        case .userNotFoundException(let exception):
            return AuthError.service(exception.message ?? "User not found error",
                                     AuthPluginErrorConstants.userNotFoundError,
                                     AWSCognitoAuthError.userNotFound)
        case .unknown(let serviceError):
            let statusCode = serviceError._statusCode?.rawValue ?? -1
            let message = serviceError._message ?? ""
            return .unknown("Unknown service error occurred with status \(statusCode) \(message)")
        case .forbiddenException(let forbiddenException):
            return .service(forbiddenException.message ?? "Access to the requested resource is forbidden",
                            AuthPluginErrorConstants.forbiddenError)        }
    }
}
