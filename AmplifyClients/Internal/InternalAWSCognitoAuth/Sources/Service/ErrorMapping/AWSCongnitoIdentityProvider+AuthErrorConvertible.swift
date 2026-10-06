//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import AWSCognitoIdentityProvider
import Foundation
@_spi(UnknownAWSHTTPServiceError) import AWSClientRuntime

extension ForbiddenException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Access to the requested resource is forbidden" }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.forbiddenError
        )
    }
}

extension InternalErrorException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Internal exception occurred" }

    package var engineError: EngineAuthError {
        .unknown(properties.message ?? fallbackDescription)
    }
}

extension InvalidParameterException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Invalid parameter error" }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.invalidParameterError,
            EngineServiceErrorCode.invalidParameter
        )
    }
}

extension InvalidPasswordException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Encountered invalid password." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.invalidPasswordError,
            EngineServiceErrorCode.invalidPassword
        )
    }
}

extension LimitExceededException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Limit exceeded error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.limitExceededError,
            EngineServiceErrorCode.limitExceeded
        )
    }
}

extension NotAuthorizedException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Not authorized error." }

    package var engineError: EngineAuthError {
        .notAuthorized(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.notAuthorizedError
        )
    }
}

extension PasswordResetRequiredException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Password reset required error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.passwordResetRequired,
            EngineServiceErrorCode.passwordResetRequired
        )
    }
}

extension ResourceNotFoundException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Resource not found error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.resourceNotFoundError,
            EngineServiceErrorCode.resourceNotFound
        )
    }
}

extension TooManyRequestsException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Too many requests error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.tooManyRequestError,
            EngineServiceErrorCode.requestLimitExceeded
        )
    }
}

extension UserNotConfirmedException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "User not confirmed error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.userNotConfirmedError,
            EngineServiceErrorCode.userNotConfirmed
        )
    }
}

extension UserNotFoundException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "User not found error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.userNotFoundError,
            EngineServiceErrorCode.userNotFound
        )
    }
}

extension CodeMismatchException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Provided code does not match what the server was expecting." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.codeMismatchError,
            EngineServiceErrorCode.codeMismatch
        )
    }
}

extension InvalidLambdaResponseException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Invalid lambda response error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.lambdaError,
            EngineServiceErrorCode.lambda
        )
    }
}

extension ExpiredCodeException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Provided code has expired." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.codeExpiredError,
            EngineServiceErrorCode.codeExpired
        )
    }
}

extension TooManyFailedAttemptsException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Too many failed attempts error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.tooManyFailedError,
            EngineServiceErrorCode.failedAttemptsLimitExceeded
        )
    }
}

extension UnexpectedLambdaException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Unexpected lambda error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.lambdaError,
            EngineServiceErrorCode.lambda
        )
    }
}

extension UserLambdaValidationException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "User lambda validation error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.lambdaError,
            EngineServiceErrorCode.lambda
        )
    }
}

extension AliasExistsException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Alias exists error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.aliasExistsError,
            EngineServiceErrorCode.aliasExists
        )
    }
}

extension InvalidUserPoolConfigurationException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Invalid UserPool Configuration error." }

    package var engineError: EngineAuthError {
        .configuration(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.configurationError
        )
    }
}

extension CodeDeliveryFailureException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Code Delivery Failure error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.codeDeliveryError,
            EngineServiceErrorCode.codeDelivery
        )
    }
}

extension InvalidEmailRoleAccessPolicyException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Invalid email role access policy error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.invalidEmailRoleError,
            EngineServiceErrorCode.emailRole
        )
    }
}

extension InvalidSmsRoleAccessPolicyException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Invalid SMS Role Access Policy error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.invalidSMSRoleError,
            EngineServiceErrorCode.smsRole
        )
    }
}

extension InvalidSmsRoleTrustRelationshipException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Invalid SMS Role Trust Relationship error." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.invalidSMSRoleError,
            EngineServiceErrorCode.smsRole
        )
    }
}

extension MFAMethodNotFoundException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Amazon Cognito cannot find a multi-factor authentication (MFA) method." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.mfaMethodNotFoundError,
            EngineServiceErrorCode.mfaMethodNotFound
        )
    }
}

extension SoftwareTokenMFANotFoundException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Software token TOTP multi-factor authentication (MFA) is not enabled for the user pool." }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.softwareTokenNotFoundError,
            EngineServiceErrorCode.softwareTokenMFANotEnabled
        )
    }
}

extension UsernameExistsException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Username exists error" }

    package var engineError: EngineAuthError {
        .service(
            properties.message ?? fallbackDescription,
            AuthPluginErrorConstants.userNameExistsError,
            EngineServiceErrorCode.usernameExists
        )
    }
}

extension AWSCognitoIdentityProvider.ConcurrentModificationException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Concurrent modification error" }

    package var engineError: EngineAuthError {
        .service(
            message ?? fallbackDescription,
            AuthPluginErrorConstants.concurrentModificationException
        )
    }
}

extension AWSCognitoIdentityProvider.EnableSoftwareTokenMFAException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "Unable to enable software token MFA" }

    package var engineError: EngineAuthError {
        .service(
            message ?? fallbackDescription,
            AuthPluginErrorConstants.softwareTokenNotFoundError,
            EngineServiceErrorCode.softwareTokenMFANotEnabled
        )
    }
}

extension AWSCognitoIdentityProvider.WebAuthnChallengeNotFoundException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "The credentials provided don't match an existing request" }

    package var engineError: EngineAuthError {
        .service(
            message ?? fallbackDescription,
            AuthPluginErrorConstants.webAuthnChallengeNotFound,
            EngineServiceErrorCode.webAuthnChallengeNotFound
        )
    }
}

extension AWSCognitoIdentityProvider.WebAuthnClientMismatchException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "The App client doesn't support WebAuthn authentication" }

    package var engineError: EngineAuthError {
        .service(
            message ?? fallbackDescription,
            AuthPluginErrorConstants.webAuthnClientMismatch,
            EngineServiceErrorCode.webAuthnClientMismatch
        )
    }
}

extension AWSCognitoIdentityProvider.WebAuthnCredentialNotSupportedException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "The device is unsupported" }

    package var engineError: EngineAuthError {
        .service(
            message ?? fallbackDescription,
            AuthPluginErrorConstants.webAuthnCredentialNotSupported,
            EngineServiceErrorCode.webAuthnNotSupported
        )
    }
}

extension AWSCognitoIdentityProvider.WebAuthnNotEnabledException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "WebAuthn authentication is not enabled" }

    package var engineError: EngineAuthError {
        .service(
            message ?? fallbackDescription,
            AuthPluginErrorConstants.webAuthnNotEnabled,
            EngineServiceErrorCode.webAuthnNotEnabled
        )
    }
}

extension AWSCognitoIdentityProvider.WebAuthnOriginNotAllowedException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "The device origin is not registered as an allowed origin" }

    package var engineError: EngineAuthError {
        .service(
            message ?? fallbackDescription,
            AuthPluginErrorConstants.webAuthnOriginNotAllowed,
            EngineServiceErrorCode.webAuthnOriginNotAllowed
        )
    }
}

extension AWSCognitoIdentityProvider.WebAuthnRelyingPartyMismatchException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "The credential does not match the relying party ID" }

    package var engineError: EngineAuthError {
        .service(
            message ?? fallbackDescription,
            AuthPluginErrorConstants.webAuthnRelyingPartyMismatch,
            EngineServiceErrorCode.webAuthnRelyingPartyMismatch
        )
    }
}

extension AWSCognitoIdentityProvider.WebAuthnConfigurationMissingException: EngineAuthErrorConvertible {
    var fallbackDescription: String { "The WebAuthm configuration is missing" }

    package var engineError: EngineAuthError {
        .service(
            message ?? fallbackDescription,
            AuthPluginErrorConstants.webAuthnConfigurationMissing,
            EngineServiceErrorCode.webAuthnConfigurationMissing
        )
    }
}

extension AWSClientRuntime.UnknownAWSHTTPServiceError: EngineAuthErrorConvertible {
    var fallbackDescription: String { "" }

    package var engineError: EngineAuthError {
        .unknown(
            """
            Unknown service error occured with:
            - status: \(httpResponse.statusCode)
            - message: \(message ?? fallbackDescription)
            """,
            self
        )
    }
}
