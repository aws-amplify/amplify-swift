//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
import Amplify

extension ChangePasswordOutputError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {

        case .internalErrorException(let exception):
            return .unknown(exception.message ?? "Internal exception occurred")

        case .invalidParameterException(let exception):
            return AuthError.service(exception.message ?? "Invalid parameter error",
                                     AuthPluginErrorConstants.invalidParameterError,
                                     AWSCognitoAuthError.invalidParameter)
        case .notAuthorizedException(let exception):
            return AuthError.notAuthorized(exception.message ?? "Not authorized error",
                                           AuthPluginErrorConstants.notAuthorizedError)
        case .passwordResetRequiredException(let exception):
            return AuthError.service(exception.message ?? "Password reset required error",
                                     AuthPluginErrorConstants.passwordResetRequired,
                                     AWSCognitoAuthError.passwordResetRequired)
        case .resourceNotFoundException(let exception):
            return AuthError.service(exception.message ?? "Resource not found error",
                                     AuthPluginErrorConstants.resourceNotFoundError,
                                     AWSCognitoAuthError.resourceNotFound)
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
        case .unknown(let serviceError):
            let statusCode = serviceError._statusCode?.rawValue ?? -1
            let message = serviceError._message ?? ""
            return .unknown("Unknown service error occurred with status \(statusCode) \(message)")
        case .invalidPasswordException(let exception):
            return AuthError.service(exception.message ?? "Encountered invalid password.",
                                     AuthPluginErrorConstants.invalidPasswordError,
                                     AWSCognitoAuthError.invalidPassword)
        case .limitExceededException(let limitExceededException):
            return .service(limitExceededException.message ?? "Limit exceeded error",
                            AuthPluginErrorConstants.limitExceededError,
                            AWSCognitoAuthError.limitExceeded)
        default:
            return .unknown("")
        }
    }
}
