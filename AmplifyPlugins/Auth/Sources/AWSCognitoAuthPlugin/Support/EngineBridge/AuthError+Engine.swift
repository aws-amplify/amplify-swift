//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation
import InternalAWSCognitoAuth

// The plugin boundary for engine errors. This is the only place that converts between
// `AuthError` / `AWSCognitoAuthError` and the engine's `EngineAuthError` / `EngineServiceErrorCode`.
// Both directions are total and lossless: the same case, the same strings, and the underlying error
// bridged case for case. `EngineAuthErrorBridgeTests` round-trips every case both ways.
//
// This file does not import `AmplifyFoundation`, so `AuthError`'s payload types need no qualifying.

extension AuthError {

    /// The `AuthError` for an engine error: same case, same strings, underlying error bridged.
    init(_ engineError: EngineAuthError) {
        switch engineError {
        case .configuration(let description, let suggestion, let error):
            self = .configuration(description, suggestion, AuthError.bridgeUnderlyingError(error))
        case .service(let description, let suggestion, let error):
            self = .service(description, suggestion, AuthError.bridgeUnderlyingError(error))
        case .unknown(let description, let error):
            self = .unknown(description, AuthError.bridgeUnderlyingError(error))
        case .validation(let field, let description, let suggestion, let error):
            self = .validation(field, description, suggestion, AuthError.bridgeUnderlyingError(error))
        case .notAuthorized(let description, let suggestion, let error):
            self = .notAuthorized(description, suggestion, AuthError.bridgeUnderlyingError(error))
        case .invalidState(let description, let suggestion, let error):
            self = .invalidState(description, suggestion, AuthError.bridgeUnderlyingError(error))
        case .signedOut(let description, let suggestion, let error):
            self = .signedOut(description, suggestion, AuthError.bridgeUnderlyingError(error))
        case .sessionExpired(let description, let suggestion, let error):
            self = .sessionExpired(description, suggestion, AuthError.bridgeUnderlyingError(error))
        }
    }

    /// The `AuthError` for any error the plugin or the engine can convert, or `nil`.
    ///
    /// Tries the plugin's `AuthErrorConvertible` first, then the engine's `EngineAuthErrorConvertible`.
    /// This replaces `catch let error as AuthErrorConvertible` in the glue: the SDK exceptions and the
    /// engine's errors are `EngineAuthErrorConvertible` only, so a bare cast would silently stop matching
    /// them.
    init?(converting error: Error) {
        if let convertible = error as? AuthErrorConvertible {
            self = convertible.authError
        } else if let convertible = error as? EngineAuthErrorConvertible {
            self = AuthError(convertible.engineError)
        } else {
            return nil
        }
    }

    /// An engine error's underlying error, as the plugin surfaces it.
    ///
    /// - `EngineServiceErrorCode` becomes `AWSCognitoAuthError`, case for case, so
    ///   `underlyingError as? AWSCognitoAuthError` keeps working;
    /// - `EngineAuthError` becomes `AuthError`, recursively;
    /// - `EngineCredentialStoreError` becomes `KeychainStoreError`, case for case, so
    ///   `underlyingError as? KeychainStoreError` keeps working;
    /// - anything else (SDK exceptions, `URLError`, …) is passed through.
    static func bridgeUnderlyingError(_ error: Error?) -> Error? {
        switch error {
        case let code as EngineServiceErrorCode:
            return AWSCognitoAuthError(code)
        case let engineError as EngineAuthError:
            return AuthError(engineError)
        case let storeError as EngineCredentialStoreError:
            return KeychainStoreError(storeError)
        default:
            return error
        }
    }

    /// Runs `body`, rethrowing an `EngineAuthError` as the `AuthError` of the same case and strings. For
    /// engine code that the plugin calls directly and whose error leaves the plugin as it is: the
    /// custom-endpoint validation `ConfigurationHelper` runs at configuration time.
    static func rethrowingEngineError<Value>(_ body: () throws -> Value) throws -> Value {
        do {
            return try body()
        } catch let error as EngineAuthError {
            throw AuthError(error)
        }
    }
}

extension EngineAuthError {

    /// The engine error for an `AuthError`: same case, same strings, underlying error bridged the
    /// other way. Used where the glue builds an error that enters engine state.
    init(_ authError: AuthError) {
        switch authError {
        case .configuration(let description, let suggestion, let error):
            self = .configuration(description, suggestion, EngineAuthError.bridgeUnderlyingError(error))
        case .service(let description, let suggestion, let error):
            self = .service(description, suggestion, EngineAuthError.bridgeUnderlyingError(error))
        case .unknown(let description, let error):
            self = .unknown(description, EngineAuthError.bridgeUnderlyingError(error))
        case .validation(let field, let description, let suggestion, let error):
            self = .validation(field, description, suggestion, EngineAuthError.bridgeUnderlyingError(error))
        case .notAuthorized(let description, let suggestion, let error):
            self = .notAuthorized(description, suggestion, EngineAuthError.bridgeUnderlyingError(error))
        case .invalidState(let description, let suggestion, let error):
            self = .invalidState(description, suggestion, EngineAuthError.bridgeUnderlyingError(error))
        case .signedOut(let description, let suggestion, let error):
            self = .signedOut(description, suggestion, EngineAuthError.bridgeUnderlyingError(error))
        case .sessionExpired(let description, let suggestion, let error):
            self = .sessionExpired(description, suggestion, EngineAuthError.bridgeUnderlyingError(error))
        }
    }

    /// The inverse of `AuthError.bridgeUnderlyingError(_:)`: `AWSCognitoAuthError` becomes
    /// `EngineServiceErrorCode`, `AuthError` becomes `EngineAuthError`, `KeychainStoreError` becomes
    /// `EngineCredentialStoreError`, anything else is passed through.
    static func bridgeUnderlyingError(_ error: Error?) -> Error? {
        switch error {
        case let code as AWSCognitoAuthError:
            return EngineServiceErrorCode(code)
        case let authError as AuthError:
            return EngineAuthError(authError)
        case let storeError as KeychainStoreError:
            return EngineCredentialStoreError(storeError)
        default:
            return error
        }
    }
}

extension AWSCognitoAuthError {

    // One case per line; the switch is exhaustive on purpose.
    // swiftlint:disable cyclomatic_complexity
    /// The public service code for an engine one: same case name.
    init(_ code: EngineServiceErrorCode) {
        switch code {
        case .userNotFound: self = .userNotFound
        case .userNotConfirmed: self = .userNotConfirmed
        case .usernameExists: self = .usernameExists
        case .aliasExists: self = .aliasExists
        case .codeDelivery: self = .codeDelivery
        case .codeMismatch: self = .codeMismatch
        case .codeExpired: self = .codeExpired
        case .invalidParameter: self = .invalidParameter
        case .invalidPassword: self = .invalidPassword
        case .limitExceeded: self = .limitExceeded
        case .mfaMethodNotFound: self = .mfaMethodNotFound
        case .softwareTokenMFANotEnabled: self = .softwareTokenMFANotEnabled
        case .passwordResetRequired: self = .passwordResetRequired
        case .resourceNotFound: self = .resourceNotFound
        case .failedAttemptsLimitExceeded: self = .failedAttemptsLimitExceeded
        case .requestLimitExceeded: self = .requestLimitExceeded
        case .lambda: self = .lambda
        case .deviceNotTracked: self = .deviceNotTracked
        case .errorLoadingUI: self = .errorLoadingUI
        case .userCancelled: self = .userCancelled
        case .invalidAccountTypeException: self = .invalidAccountTypeException
        case .network: self = .network
        case .smsRole: self = .smsRole
        case .emailRole: self = .emailRole
        case .externalServiceException: self = .externalServiceException
        case .limitExceededException: self = .limitExceededException
        case .resourceConflictException: self = .resourceConflictException
        case .webAuthnChallengeNotFound: self = .webAuthnChallengeNotFound
        case .webAuthnClientMismatch: self = .webAuthnClientMismatch
        case .webAuthnNotSupported: self = .webAuthnNotSupported
        case .webAuthnNotEnabled: self = .webAuthnNotEnabled
        case .webAuthnOriginNotAllowed: self = .webAuthnOriginNotAllowed
        case .webAuthnRelyingPartyMismatch: self = .webAuthnRelyingPartyMismatch
        case .webAuthnConfigurationMissing: self = .webAuthnConfigurationMissing
        }
    }
    // swiftlint:enable cyclomatic_complexity
}

extension EngineServiceErrorCode {

    // One case per line; the switch is exhaustive on purpose.
    // swiftlint:disable cyclomatic_complexity
    /// The engine service code for a public one: same case name.
    init(_ code: AWSCognitoAuthError) {
        switch code {
        case .userNotFound: self = .userNotFound
        case .userNotConfirmed: self = .userNotConfirmed
        case .usernameExists: self = .usernameExists
        case .aliasExists: self = .aliasExists
        case .codeDelivery: self = .codeDelivery
        case .codeMismatch: self = .codeMismatch
        case .codeExpired: self = .codeExpired
        case .invalidParameter: self = .invalidParameter
        case .invalidPassword: self = .invalidPassword
        case .limitExceeded: self = .limitExceeded
        case .mfaMethodNotFound: self = .mfaMethodNotFound
        case .softwareTokenMFANotEnabled: self = .softwareTokenMFANotEnabled
        case .passwordResetRequired: self = .passwordResetRequired
        case .resourceNotFound: self = .resourceNotFound
        case .failedAttemptsLimitExceeded: self = .failedAttemptsLimitExceeded
        case .requestLimitExceeded: self = .requestLimitExceeded
        case .lambda: self = .lambda
        case .deviceNotTracked: self = .deviceNotTracked
        case .errorLoadingUI: self = .errorLoadingUI
        case .userCancelled: self = .userCancelled
        case .invalidAccountTypeException: self = .invalidAccountTypeException
        case .network: self = .network
        case .smsRole: self = .smsRole
        case .emailRole: self = .emailRole
        case .externalServiceException: self = .externalServiceException
        case .limitExceededException: self = .limitExceededException
        case .resourceConflictException: self = .resourceConflictException
        case .webAuthnChallengeNotFound: self = .webAuthnChallengeNotFound
        case .webAuthnClientMismatch: self = .webAuthnClientMismatch
        case .webAuthnNotSupported: self = .webAuthnNotSupported
        case .webAuthnNotEnabled: self = .webAuthnNotEnabled
        case .webAuthnOriginNotAllowed: self = .webAuthnOriginNotAllowed
        case .webAuthnRelyingPartyMismatch: self = .webAuthnRelyingPartyMismatch
        case .webAuthnConfigurationMissing: self = .webAuthnConfigurationMissing
        }
    }
    // swiftlint:enable cyclomatic_complexity
}
