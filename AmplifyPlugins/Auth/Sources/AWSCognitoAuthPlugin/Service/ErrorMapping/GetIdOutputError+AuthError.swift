//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentity
import Amplify

extension GetIdOutputError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .externalServiceException(let externalServiceException):
            return .service(externalServiceException.message ?? "External service threw error",
                            AuthPluginErrorConstants.externalServiceException,
                            AWSCognitoAuthError.externalServiceException)
        case .internalErrorException(let internalErrorException):
            return .unknown(internalErrorException.message ?? "Internal exception occurred")
        case .invalidParameterException(let invalidParameterException):
            return .service(invalidParameterException.message ?? "Invalid parameter error",
                            AuthPluginErrorConstants.invalidParameterError,
                            AWSCognitoAuthError.invalidParameter)
        case .limitExceededException(let limitExceededException):
            return .service(limitExceededException.message ?? "Limit exceeded error",
                            AuthPluginErrorConstants.limitExceededException,
                            AWSCognitoAuthError.limitExceededException)
        case .notAuthorizedException(let notAuthorizedException):
            return .notAuthorized(notAuthorizedException.message ?? "Not authorized Error",
                                  AuthPluginErrorConstants.notAuthorizedError,
                                  nil)
        case .resourceConflictException(let resourceConflictException):
            return .service(resourceConflictException.message ?? "Resource conflict error",
                            AuthPluginErrorConstants.resourceConflictException,
                            AWSCognitoAuthError.resourceConflictException)
        case .resourceNotFoundException(let resourceNotFoundException):
            return AuthError.service(resourceNotFoundException.message ?? "Resource not found error",
                                     AuthPluginErrorConstants.resourceNotFoundError,
                                     AWSCognitoAuthError.resourceNotFound)
        case .tooManyRequestsException(let tooManyRequestsException):
            return .service(tooManyRequestsException.message ?? "Too many requests error",
                            AuthPluginErrorConstants.tooManyRequestError,
                            AWSCognitoAuthError.requestLimitExceeded)
        case .unknown(let unknownAWSHttpServiceError):
            let statusCode = unknownAWSHttpServiceError._statusCode?.rawValue ?? -1
            let message = unknownAWSHttpServiceError._message ?? ""
            return .unknown("Unknown service error occurred with status \(statusCode) \(message)")
        @unknown default:
            return .unknown("Unknown service error occurred")
        }
    }

}
