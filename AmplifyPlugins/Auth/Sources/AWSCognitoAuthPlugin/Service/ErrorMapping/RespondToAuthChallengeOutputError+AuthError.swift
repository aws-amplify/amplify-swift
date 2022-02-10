//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
import Amplify

extension RespondToAuthChallengeOutputError: AuthErrorConvertible {

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
        case .invalidPasswordException(let exception):
            return AuthError.service(exception.message ?? "Encountered invalid password.",
                                     AuthPluginErrorConstants.invalidPasswordError,
                                     AWSCognitoAuthError.invalidPassword)
        case .mFAMethodNotFoundException(let exception):
            return AuthError.service(exception.message ?? "Amazon Cognito cannot find a multi-factor authentication (MFA) method.",
                                     AuthPluginErrorConstants.mfaMethodNotFoundError,
                                     AWSCognitoAuthError.mfaMethodNotFound)
        case .softwareTokenMFANotFoundException(let exception):
            return AuthError.service(exception.message ?? "Software token TOTP multi-factor authentication (MFA) is not enabled for the user pool.",
                                     AuthPluginErrorConstants.softwareTokenNotFoundError,
                                     AWSCognitoAuthError.softwareTokenMFANotEnabled)
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
        case .invalidUserPoolConfigurationException(let exception):
            return AuthError.configuration(exception.message ?? "Invalid UserPool Configuration error",
                                           AuthPluginErrorConstants.configurationError)
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

        }
    }
}
