//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSCognitoIdentity
import AWSClientRuntime

// AWSCognitoIdentity
extension AWSCognitoIdentity.ExternalServiceException: AuthErrorConvertible {
    var fallbackDescription: String { "External service threw error." }

    var authError: AuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.externalServiceException,
            AWSCognitoAuthError.externalServiceException
        )
    }
}

extension AWSCognitoIdentity.InternalErrorException: AuthErrorConvertible {
    var fallbackDescription: String { "Internal exception occurred" }

    var authError: AuthError {
        .unknown(properties.message ?? fallbackDescription)
    }
}

// AWSCognitoIdentity
extension AWSCognitoIdentity.InvalidIdentityPoolConfigurationException: AuthErrorConvertible {
    var fallbackDescription: String { "Invalid IdentityPool Configuration error." }

    var authError: AuthError {
        .configuration(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.configurationError
        )
    }
}

extension AWSCognitoIdentity.InvalidParameterException: AuthErrorConvertible {
    var fallbackDescription: String { "Invalid parameter error" }

    var authError: AuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.invalidParameterError,
            AWSCognitoAuthError.invalidParameter
        )
    }
}

extension AWSCognitoIdentity.NotAuthorizedException: AuthErrorConvertible {
    var fallbackDescription: String { "Not authorized error." }

    var authError: AuthError {
        .notAuthorized(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.notAuthorizedError
        )
    }
}

extension AWSCognitoIdentity.ResourceConflictException: AuthErrorConvertible {
    var fallbackDescription: String { "Resource conflict error." }

    var authError: AuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.resourceConflictException,
            AWSCognitoAuthError.resourceConflictException
        )
    }
}

extension AWSCognitoIdentity.ResourceNotFoundException: AuthErrorConvertible {
    var fallbackDescription: String { "Resource not found error." }

    var authError: AuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.resourceNotFoundError,
            AWSCognitoAuthError.resourceNotFound
        )
    }
}

extension AWSCognitoIdentity.TooManyRequestsException: AuthErrorConvertible {
    var fallbackDescription: String { "Too many requests error." }

    var authError: AuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.tooManyRequestError,
            AWSCognitoAuthError.requestLimitExceeded
        )
    }
}


extension AWSCognitoIdentity.LimitExceededException: AuthErrorConvertible {
    var fallbackDescription: String { "Too many requests error." }

    var authError: AuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.limitExceededException,
            AWSCognitoAuthError.limitExceededException
        )
    }
}
