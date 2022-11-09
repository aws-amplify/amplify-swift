//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
import Amplify

extension GetUserAttributeVerificationCodeOutputError: AuthErrorConvertible {

    var authError: AuthError {
        switch self {
        case .codeDeliveryFailureException(let exception):
            return .service(exception.message ?? "Code Delivery Failure error",
                            AuthPluginErrorConstants.codeDeliveryError,
                            AWSCognitoAuthError.codeDelivery)
        case .internalErrorException(let exception):
            return .unknown(exception.message ?? "Internal exception occurred")
        case .invalidEmailRoleAccessPolicyException(let exception):
            return .service(exception.message ?? "Invalid email role access policy error",
                            AuthPluginErrorConstants.invalidEmailRoleError,
                            AWSCognitoAuthError.emailRole)
        case .invalidLambdaResponseException(let exception):
            return .service(exception.message ?? "Invalid lambda response error",
                            AuthPluginErrorConstants.lambdaError,
                            AWSCognitoAuthError.lambda)
        case .invalidParameterException(let exception):
            return .service(exception.message ?? "Invalid parameter error",
                            AuthPluginErrorConstants.invalidParameterError,
                            AWSCognitoAuthError.invalidParameter)
        case .invalidSmsRoleAccessPolicyException(let exception):
            return .service(exception.message ?? "Invalid SMS Role Access Policy error",
                            AuthPluginErrorConstants.invalidParameterError,
                            AWSCognitoAuthError.smsRole)
        case .invalidSmsRoleTrustRelationshipException(let exception):
            return .service(exception.message ?? "Invalid SMS Role Trust Relationship error",
                            AuthPluginErrorConstants.invalidParameterError,
                            AWSCognitoAuthError.smsRole)
        case .limitExceededException(let limitExceededException):
            return .service(limitExceededException.message ?? "Limit exceeded error",
                            AuthPluginErrorConstants.limitExceededError,
                            AWSCognitoAuthError.limitExceeded)
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
        case .unexpectedLambdaException(let exception):
            return .service(exception.message ?? "Invalid lambda response error",
                            AuthPluginErrorConstants.lambdaError,
                            AWSCognitoAuthError.lambda)
        case .userLambdaValidationException(let exception):
            return .service(exception.message ?? "Invalid lambda response error",
                            AuthPluginErrorConstants.lambdaError,
                            AWSCognitoAuthError.lambda)
        case .userNotConfirmedException(let userNotConfirmedException):
            return .service(userNotConfirmedException.message ?? "User not confirmed error",
                            AuthPluginErrorConstants.userNotConfirmedError,
                            AWSCognitoAuthError.userNotConfirmed)
        case .userNotFoundException(let userNotFoundException):
            return .service(userNotFoundException.message ?? "User not found error",
                            AuthPluginErrorConstants.userNotFoundError,
                            AWSCognitoAuthError.userNotFound)
        case .unknown(let unknownAWSHttpServiceError):
            let statusCode = unknownAWSHttpServiceError._statusCode?.rawValue ?? -1
            let message = unknownAWSHttpServiceError._message ?? ""
            return .unknown("Unknown service error occurred with status \(statusCode) \(message)")
        default: return .unknown("")

        }
    }

}
