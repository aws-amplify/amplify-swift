//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
import Amplify

extension ForgetDeviceOutputError: AuthErrorConvertible {

    var authError: AuthError {
        switch self {
        case .internalErrorException(let exception):
            return .unknown(exception.message ?? "Internal exception occurred")
        case .invalidParameterException(let exception):
            return AuthError.service(exception.message ?? "Invalid parameter error",
                                     AuthPluginErrorConstants.invalidParameterError,
                                     AWSCognitoAuthError.invalidParameter)
        case .invalidUserPoolConfigurationException(let exception):
            return .configuration(exception.message ?? "Invalid UserPool Configuration error",
                                  AuthPluginErrorConstants.configurationError)
        case .notAuthorizedException(let exception):
            return .notAuthorized(exception.message ?? "Not authorized error",
                                  AuthPluginErrorConstants.notAuthorizedError)
        case .passwordResetRequiredException(let exception):
            return .service(exception.message ?? "Password reset required error",
                            AuthPluginErrorConstants.passwordResetRequired,
                            AWSCognitoAuthError.passwordResetRequired)
        case .resourceNotFoundException(let exception):
            return .service(exception.message ?? "Resource not found error",
                            AuthPluginErrorConstants.resourceNotFoundError,
                            AWSCognitoAuthError.resourceNotFound)
        case .tooManyRequestsException(let exception):
            return .service(exception.message ?? "Too many requests error",
                            AuthPluginErrorConstants.tooManyRequestError,
                            AWSCognitoAuthError.requestLimitExceeded)
        case .userNotConfirmedException(let userNotConfirmedException):
            return .service(userNotConfirmedException.message ?? "User not confirmed error",
                            AuthPluginErrorConstants.userNotConfirmedError,
                            AWSCognitoAuthError.userNotConfirmed)
        case .userNotFoundException(let exception):
            return .service(exception.message ?? "User not found error",
                            AuthPluginErrorConstants.userNotFoundError,
                            AWSCognitoAuthError.userNotFound)
        case .unknown(let serviceError):
            let statusCode = serviceError._statusCode?.rawValue ?? -1
            let message = serviceError._message ?? ""
            return .unknown("Unknown service error occurred with status \(statusCode) \(message)")
            
        case .forbiddenException(let forbiddenException):
            return .service(forbiddenException.message ?? "Access to the requested resource is forbidden",
                            AuthPluginErrorConstants.forbiddenError)
        }
    }
}
