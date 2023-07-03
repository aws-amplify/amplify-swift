//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCognitoIdentityProvider

extension AssociateSoftwareTokenOutputError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .concurrentModificationException(let concurrentModificationException):
            return .service(
                concurrentModificationException.message ?? "Concurrent modification error",
                AuthPluginErrorConstants.concurrentModificationException)
        case .forbiddenException(let forbiddenException):
            return .service(
                forbiddenException.message ?? "Access to the requested resource is forbidden",
                AuthPluginErrorConstants.forbiddenError)
        case .internalErrorException(let internalErrorException):
            return .unknown(
                internalErrorException.message ?? "Internal exception occurred")
        case .invalidParameterException(let invalidParameterException):
            return .service(
                invalidParameterException.message ?? "Invalid parameter error",
                AuthPluginErrorConstants.invalidParameterError,
                AWSCognitoAuthError.invalidParameter)
        case .notAuthorizedException(let notAuthorizedException):
            return .notAuthorized(
                notAuthorizedException.message ?? "Not authorized Error",
                AuthPluginErrorConstants.notAuthorizedError,
                nil)
        case .resourceNotFoundException(let resourceNotFoundException):
            return AuthError.service(
                resourceNotFoundException.message ?? "Resource not found error",
                AuthPluginErrorConstants.resourceNotFoundError,
                AWSCognitoAuthError.resourceNotFound)
        case .softwareTokenMFANotFoundException(let exception):
            return AuthError.service(
                exception.message ?? "Software token TOTP multi-factor authentication (MFA) is not enabled for the user pool.",
                AuthPluginErrorConstants.softwareTokenNotFoundError,
                AWSCognitoAuthError.mfaMethodNotFound)
        case .unknown(let unknownAWSHttpServiceError):
            let statusCode = unknownAWSHttpServiceError._statusCode?.rawValue ?? -1
            let message = unknownAWSHttpServiceError._message ?? ""
            return .unknown("Unknown service error occurred with status \(statusCode) \(message)")
        }
    }
}
