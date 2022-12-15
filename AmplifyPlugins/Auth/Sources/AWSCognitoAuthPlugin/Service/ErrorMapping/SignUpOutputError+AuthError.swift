//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

extension SignUpOutputError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .codeDeliveryFailureException(let exception):

            return .service(
                exception.message ?? "Code Delivery Failure error",
                AuthPluginErrorConstants.codeDeliveryError,
                AWSCognitoAuthError.codeDelivery
            )
        case .internalErrorException(let exception):

            return .unknown(
                exception.message ?? "Internal exception occurred"
            )
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

            return .service(
                exception.message ?? "Invalid parameter error",
                AuthPluginErrorConstants.invalidParameterError,
                AWSCognitoAuthError.invalidParameter
            )
        case .invalidPasswordException(let exception):

            return .service(
                exception.message ?? "Invalid password error",
                AuthPluginErrorConstants.invalidPasswordError,
                AWSCognitoAuthError.invalidPassword
            )
        case .invalidSmsRoleAccessPolicyException(let exception):

            return .service(
                exception.message ?? "Invalid SMS role access policy error",
                AuthPluginErrorConstants.invalidSMSRoleError,
                AWSCognitoAuthError.smsRole
            )
        case .invalidSmsRoleTrustRelationshipException(let exception):

            return .service(
                exception.message ?? "Invalid SMS role access policy error",
                AuthPluginErrorConstants.invalidSMSRoleError,
                AWSCognitoAuthError.smsRole
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
        case .usernameExistsException(let exception):

            return .service(
                exception.message ?? "Username exists error",
                AuthPluginErrorConstants.userNameExistsError,
                AWSCognitoAuthError.usernameExists
            )
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
