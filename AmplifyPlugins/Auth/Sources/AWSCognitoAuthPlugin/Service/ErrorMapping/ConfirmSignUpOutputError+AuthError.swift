//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

extension ConfirmSignUpOutputError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .aliasExistsException(let exception):

            return .service(
                exception.message ?? "Alias exists error",
                AuthPluginErrorConstants.aliasExistsError,
                AWSCognitoAuthError.aliasExists
            )
        case .codeMismatchException(let exception):

            return .service(
                exception.message ?? "Code mismatch error",
                AuthPluginErrorConstants.codeMismatchError,
                AWSCognitoAuthError.codeMismatch
            )
        case .expiredCodeException(let exception):

            return .service(
                exception.message ?? "Expired code error",
                AuthPluginErrorConstants.codeExpiredError,
                AWSCognitoAuthError.codeExpired
            )
        case .limitExceededException(let exception):

            return .service(
                exception.message ?? "Limit exceeded error",
                AuthPluginErrorConstants.limitExceededError,
                AWSCognitoAuthError.limitExceeded
            )
        case .tooManyFailedAttemptsException(let exception):

            return .service(
                exception.message ?? "Too many failed attempts error",
                AuthPluginErrorConstants.tooManyFailedError,
                AWSCognitoAuthError.requestLimitExceeded
            )
        case .userNotFoundException(let exception):

            return .service(
                exception.message ?? "User not found error",
                AuthPluginErrorConstants.userNotFoundError,
                AWSCognitoAuthError.userNotFound
            )
        case .internalErrorException(let exception):

            return .unknown(
                exception.message ?? "Internal exception occurred"
            )
        case .invalidLambdaResponseException(let exception):

            return .service(
                exception.message ?? "Invalid lambda response error",
                AuthPluginErrorConstants.lambdaError,
                AWSCognitoAuthError.lambda
            )
        case .invalidParameterException(let exception):

            return .service(
                exception.message ?? "Invalid parameter error",
                AuthPluginErrorConstants.invalidParameterError,
                AWSCognitoAuthError.invalidParameter
            )
        case .notAuthorizedException(let exception):

            return .notAuthorized(
                exception.message ?? "Not authorized error",
                AuthPluginErrorConstants.notAuthorizedError)
        case .resourceNotFoundException(let exception):

            return .service(
                exception.message ?? "Resource not found error",
                AuthPluginErrorConstants.resourceNotFoundError,
                AWSCognitoAuthError.resourceNotFound
            )
        case .tooManyRequestsException(let exception):

            return .service(
                exception.message ?? "Too many requests error",
                AuthPluginErrorConstants.tooManyRequestError,
                AWSCognitoAuthError.requestLimitExceeded
            )
        case .unexpectedLambdaException(let exception):

            return .service(
                exception.message ?? "Unexpected lambda error",
                AuthPluginErrorConstants.lambdaError,
                AWSCognitoAuthError.lambda
            )
        case .userLambdaValidationException(let exception):

            return .service(
                exception.message ?? "User lambda validation error",
                AuthPluginErrorConstants.lambdaError,
                AWSCognitoAuthError.lambda
            )

        case .unknown(let serviceError):
            let statusCode = serviceError._statusCode?.rawValue ?? -1
            let message = serviceError._message ?? ""
            return .unknown("Unknown service error occurred with status \(statusCode) \(message)")
            
        case .forbiddenException(let forbiddenException):
            return .service(forbiddenException.message ?? "Access to the requested resource is forbidden",
                            AuthPluginErrorConstants.forbiddenError)
        @unknown default:
            return .unknown("Unknown service error occurred")
        }
    }

}
