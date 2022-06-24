//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
import Amplify

extension ResendConfirmationCodeOutputError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .codeDeliveryFailureException(let exception):
            return .service(
                exception.message ?? "Code Delivery Failure error",
                AuthPluginErrorConstants.codeDeliveryError,
                AWSCognitoAuthError.codeDelivery
            )
        case .internalErrorException(let exception):
            return .unknown(exception.message ?? "Internal exception occurred")
        case .invalidEmailRoleAccessPolicyException(let exception):
            return .service(
                exception.message ?? "Invalid email role access policy error",
                AuthPluginErrorConstants.invalidEmailRoleError,
                AWSCognitoAuthError.emailRole
            )
        case .invalidLambdaResponseException(let exception):
            return .service(
                exception.message ?? "Invalid lambda response error",
                AuthPluginErrorConstants.lambdaError,
                AWSCognitoAuthError.lambda
            )
        case .invalidParameterException(let exception):
            return AuthError.service(exception.message ?? "Invalid parameter error",
                                     AuthPluginErrorConstants.invalidParameterError,
                                     AWSCognitoAuthError.invalidParameter)
        case .invalidSmsRoleAccessPolicyException(let exception):
            return AuthError.service(exception.message ?? "Invalid SMS Role Access Policy error",
                                     AuthPluginErrorConstants.invalidSMSRoleError,
                                     AWSCognitoAuthError.smsRole)
        case .invalidSmsRoleTrustRelationshipException(let exception):
            return AuthError.service(exception.message ?? "Invalid SMS Role Trust Relationship error",
                                     AuthPluginErrorConstants.invalidSMSRoleError,
                                     AWSCognitoAuthError.smsRole)
        case .limitExceededException(let exception):
            return .service(
                exception.message ?? "Limit exceeded error",
                AuthPluginErrorConstants.limitExceededError,
                AWSCognitoAuthError.limitExceeded
            )
        case .notAuthorizedException(let exception):
            return AuthError.notAuthorized(exception.message ?? "Not authorized error",
                                           AuthPluginErrorConstants.notAuthorizedError)
        case .resourceNotFoundException(let exception):
            return AuthError.service(exception.message ?? "Resource not found error",
                                     AuthPluginErrorConstants.resourceNotFoundError,
                                     AWSCognitoAuthError.resourceNotFound)
        case .tooManyRequestsException(let exception):
            return AuthError.service(exception.message ?? "Too many requests error",
                               AuthPluginErrorConstants.tooManyRequestError,
                               AWSCognitoAuthError.requestLimitExceeded)
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
        case .userNotFoundException(let exception):
            return AuthError.service(exception.message ?? "User not found error",
                                     AuthPluginErrorConstants.userNotFoundError,
                                     AWSCognitoAuthError.userNotFound)
        case .unknown(let serviceError):
            let statusCode = serviceError._statusCode?.rawValue ?? -1
            let message = serviceError._message ?? ""
            return .unknown("Unknown service error occurred with status \(statusCode) \(message)")
        }
    }
}
