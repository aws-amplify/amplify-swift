//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum AWSCognitoAuthError: Error {

    /// User not found in the system.
    case userNotFound

    /// User not confirmed in the system.
    case userNotConfirmed

    /// Username already exists in the system.
    case usernameExists

    /// Alias already exists in the system.
    case aliasExists

    /// Error in delivering the confirmation code.
    case codeDelivery

    /// Confirmation code entered is not correct.
    case codeMismatch

    /// Confirmation code has expired.
    case codeExpired

    /// One or more parameters are incorrect.
    case invalidParameter

    /// Password given is invalid.
    case invalidPassword

    /// Limit exceeded for the requested AWS resource
    case limitExceeded

    /// Amazon Cognito cannot find a multi-factor authentication (MFA) method.
    case mfaMethodNotFound

    /// Software token (TOTP) multi-factor authentication (MFA) is not enabled for the user pool.
    case softwareTokenMFANotEnabled

    /// Required to reset the password of the user.
    case passwordResetRequired

    /// Amazon Cognito service cannot find the requested resource.
    case resourceNotFound

    /// The user has made too many failed attempts for a given action.
    case failedAttemptsLimitExceeded

    /// The user has made too many requests for a given operation.
    case requestLimitExceeded

    /// Amazon Cognito service encountered an invalid AWS Lambda response or encountered an
    /// unexpected exception with the AWS Lambda service.
    case lambda

    /// Device is not tracked.
    case deviceNotTracked

    /// Error in loading the web UI.
    case errorLoadingUI

    /// User cancelled the step
    case userCancelled

    /// Requested resource is not available with the current account setup.
    case invalidAccountTypeException

    /// Request was not completed because of a network related issue
    case network

    /// SMS role related issue
    case smsRole

    /// Email role related issue
    case emailRole

    /// An external service like facebook/twitter threw an error
    case externalServiceException

    /// Limit exceeded exception. Thrown when the total number of user pools has exceeded a preset limit.
    case limitExceededException

    /// Thrown when a user tries to use a login which is already linked to another account.
    case resourceConflictException

    /// The WebAuthn credentials don't match an existing request
    case webAuthnChallengeNotFound

    /// The client doesn't support WebAuhn authentication
    case webAuthnClientMismatch

    /// WebAuthn is not supported on this device
    case webAuthnNotSupported

    /// WebAuthn is not enabled
    case webAuthnNotEnabled

    /// The device origin is not registered as an allowed origin
    case webAuthnOriginNotAllowed

    /// The relying party ID doesn't match
    case webAuthnRelyingPartyMismatch

    /// The WebAuthn configuration is missing or incomplete
    case webAuthnConfigurationMissing
}

extension AWSCognitoAuthError: LocalizedError {
    public var errorDescription: String? {
        var message: String = ""
        switch self {
        case .userNotFound:
            message = "User not found in the system."
        case .userNotConfirmed:
            message = "User not confirmed in the system."
        case .usernameExists:
            message = "Username already exists in the system."
        case .aliasExists:
            message = "Alias already exists in the system."
        case .codeDelivery:
            message = "Error in delivering the confirmation code."
        case .codeMismatch:
            message = "Confirmation code entered is not correct."
        case .codeExpired:
            message = "Confirmation code has expired."
        case .invalidParameter:
            message = "One or more parameters are incorrect."
        case .invalidPassword:
            message = "Password given is invalid."
        case .limitExceeded:
            message = "Limit exceeded for the requested AWS resource."
        case .mfaMethodNotFound:
            message = "Amazon Cognito cannot find a multi-factor authentication (MFA) method."
        case .softwareTokenMFANotEnabled:
            message = "Software token (TOTP) multi-factor authentication (MFA) is not enabled for the user pool."
        case .passwordResetRequired:
            message = "Required to reset the password of the user."
        case .resourceNotFound:
            message = "Amazon Cognito service cannot find the requested resource."
        case .failedAttemptsLimitExceeded:
            message = "The user has made too many failed attempts for a given action."
        case .requestLimitExceeded:
            message = "The user has made too many requests for a given operation."
        case .lambda:
            message = "Amazon Cognito service encountered an invalid AWS Lambda response or encountered an unexpected exception with the AWS Lambda service."
        case .deviceNotTracked:
            message = "Device is not tracked."
        case .errorLoadingUI:
            message = "Error in loading the web UI."
        case .userCancelled:
            message = "User cancelled the step."
        case .invalidAccountTypeException:
            message = "Requested resource is not available with the current account setup."
        case .network:
            message = "Request was not completed because of a network related issue."
        case .smsRole:
            message = "SMS role related issue."
        case .emailRole:
            message = "Email role related issue."
        case .externalServiceException:
            message = "An external service like facebook/twitter threw an error."
        case .limitExceededException:
            message = "Limit exceeded exception. Thrown when the total number of user pools has exceeded a preset limit."
        case .resourceConflictException:
            message = "Thrown when a user tries to use a login which is already linked to another account."
        case .webAuthnChallengeNotFound:
            message = "The WebAuthn credentials don't match an existing request."
        case .webAuthnClientMismatch:
            message = "The client doesn't support WebAuhn authentication."
        case .webAuthnNotSupported:
            message = "WebAuthn is not supported on this device."
        case .webAuthnNotEnabled:
            message = "WebAuthn is not enabled."
        case .webAuthnOriginNotAllowed:
            message = "The device origin is not registered as an allowed origin."
        case .webAuthnRelyingPartyMismatch:
            message = "The relying party ID doesn't match."
        case .webAuthnConfigurationMissing:
            message = "The WebAuthn configuration is missing or incomplete."
        }
        return "\(String(describing: Self.self)).\(self): \(message)"
    }
}
