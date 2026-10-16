//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import AWSCognitoIdentity
import Foundation

// AWSCognitoIdentity
extension AWSCognitoIdentity.ExternalServiceException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "External service threw error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.externalServiceException,
            EngineServiceErrorCode.externalServiceException
        )
    }
}

extension AWSCognitoIdentity.InternalErrorException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Internal exception occurred" }

    package var engineError: EngineAuthError {
        .unknown(properties.message ?? fallbackDescription)
    }
}

// AWSCognitoIdentity
extension AWSCognitoIdentity.InvalidIdentityPoolConfigurationException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Invalid IdentityPool Configuration error." }

    package var engineError: EngineAuthError {
        .configuration(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.configurationError
        )
    }
}

extension AWSCognitoIdentity.InvalidParameterException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Invalid parameter error" }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.invalidParameterError,
            EngineServiceErrorCode.invalidParameter
        )
    }
}

extension AWSCognitoIdentity.NotAuthorizedException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Not authorized error." }

    package var engineError: EngineAuthError {
        .notAuthorized(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.notAuthorizedError
        )
    }
}

extension AWSCognitoIdentity.ResourceConflictException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Resource conflict error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.resourceConflictException,
            EngineServiceErrorCode.resourceConflictException
        )
    }
}

extension AWSCognitoIdentity.ResourceNotFoundException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Resource not found error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.resourceNotFoundError,
            EngineServiceErrorCode.resourceNotFound
        )
    }
}

extension AWSCognitoIdentity.TooManyRequestsException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Too many requests error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.tooManyRequestError,
            EngineServiceErrorCode.requestLimitExceeded
        )
    }
}

extension AWSCognitoIdentity.LimitExceededException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Too many requests error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.limitExceededException,
            EngineServiceErrorCode.limitExceededException
        )
    }
}
