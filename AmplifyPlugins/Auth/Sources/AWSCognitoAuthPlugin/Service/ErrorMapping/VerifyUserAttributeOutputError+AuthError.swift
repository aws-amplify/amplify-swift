//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

extension VerifyUserAttributeOutputError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
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
        case .invalidParameterException(let exception):

            return .service(
                exception.message ?? "Invalid parameter error",
                AuthPluginErrorConstants.invalidParameterError,
                AWSCognitoAuthError.invalidParameter
            )
        case .notAuthorizedException(let exception):

            return .notAuthorized(
                exception.message ?? "Not authorized error",
                AuthPluginErrorConstants.notAuthorizedError
            )
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

        case .unknown(let serviceError):
            let statusCode = serviceError._statusCode?.rawValue ?? -1
            let message = serviceError._message ?? ""
            return .unknown("Unknown service error occurred with status \(statusCode) \(message)")

        case .passwordResetRequiredException(let exception):
            return .service(
                exception.message ?? "Password reset required error",
                AuthPluginErrorConstants.passwordResetRequired,
                AWSCognitoAuthError.passwordResetRequired
            )

        case .userNotConfirmedException(let exception):
            return AuthError.service(
                exception.message ?? "User not confirmed error",
                AuthPluginErrorConstants.userNotConfirmedError,
                AWSCognitoAuthError.userNotConfirmed
            )
        case .aliasExistsException(let exception):
            return AuthError.service(
                exception.message ?? "An account with this email or phone already exists.",
                AuthPluginErrorConstants.aliasExistsError,
                AWSCognitoAuthError.aliasExists)
        }
    }
}
