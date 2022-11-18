//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentity
import Amplify
import AWSCognitoIdentityProvider

extension UpdateUserAttributesOutputError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .aliasExistsException(let exception):
            return AuthError.service(exception.message ?? "An account with this email or phone already exists.",
                                     AuthPluginErrorConstants.aliasExistsError,
                                     AWSCognitoAuthError.aliasExists)
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
            return AuthError.service(exception.message ?? "Invalid lambda response error",
                                     AuthPluginErrorConstants.lambdaError,
                                     AWSCognitoAuthError.lambda)
        case .invalidParameterException(let exception):
            return AuthError.service(exception.message ?? "Invalid parameter error",
                                     AuthPluginErrorConstants.invalidParameterError,
                                     AWSCognitoAuthError.invalidParameter)
        case .invalidSmsRoleAccessPolicyException(let exception):
            return AuthError.service(exception.message ?? "Invalid SMS Role Access Policy error",
                                     AuthPluginErrorConstants.invalidParameterError,
                                     AWSCognitoAuthError.smsRole)
        case .invalidSmsRoleTrustRelationshipException(let exception):
            return AuthError.service(exception.message ?? "Invalid SMS Role Trust Relationship error",
                                     AuthPluginErrorConstants.invalidParameterError,
                                     AWSCognitoAuthError.smsRole)
        case .notAuthorizedException(let exception):
            return AuthError.notAuthorized(exception.message ?? "Not authrozied error",
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
        case .unexpectedLambdaException(let exception):
            return AuthError.service(exception.message ?? "Invalid lambda response error",
                                     AuthPluginErrorConstants.lambdaError,
                                     AWSCognitoAuthError.lambda)
        case .userLambdaValidationException(let exception):
            return AuthError.service(exception.message ?? "Invalid lambda response error",
                                     AuthPluginErrorConstants.lambdaError,
                                     AWSCognitoAuthError.lambda)
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
        case .codeDeliveryFailureException(let exception):
            return .service(exception.message ?? "Code Delivery Failure error",
                            AuthPluginErrorConstants.codeDeliveryError,
                            AWSCognitoAuthError.codeDelivery)
        case .invalidEmailRoleAccessPolicyException(let exception):
            return .service(exception.message ?? "Invalid email role access policy error",
                            AuthPluginErrorConstants.invalidEmailRoleError,
                            AWSCognitoAuthError.emailRole)
            
        case .forbiddenException(let forbiddenException):
            return .service(forbiddenException.message ?? "Access to the requested resource is forbidden",
                            AuthPluginErrorConstants.forbiddenError)
        @unknown default:
            return .unknown("Unknown service error occurred")
        }
    }

}
