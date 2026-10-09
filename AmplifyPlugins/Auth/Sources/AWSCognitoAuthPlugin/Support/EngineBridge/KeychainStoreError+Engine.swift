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

// The plugin boundary for the credential store's error. `EngineCredentialStoreError` is the
// engine's copy of `KeychainStoreError`: the same six cases with the same payloads, so both directions are
// total and lossless. Underlying errors are bridged as `AuthError`'s are. `EngineCredentialStoreErrorTests`
// round-trips every case both ways.

/// Read with `.authError` by callers that hold the public type. Moved here from `AuthErrorConvertible.swift`,
/// so that no `KeychainStoreError` is named outside the boundary files.
extension KeychainStoreError: AuthErrorConvertible {}

extension KeychainStoreError {

    /// The public error for an engine credential-store error: the same case and payload, with the
    /// underlying error bridged through `AuthError.bridgeUnderlyingError(_:)`.
    init(_ error: EngineCredentialStoreError) {
        switch error {
        case .configuration(let message):
            self = .configuration(message: message)
        case .unknown(let description, let underlyingError):
            self = .unknown(description, AuthError.bridgeUnderlyingError(underlyingError))
        case .conversionError(let description, let underlyingError):
            self = .conversionError(description, AuthError.bridgeUnderlyingError(underlyingError))
        case .codingError(let description, let underlyingError):
            self = .codingError(description, AuthError.bridgeUnderlyingError(underlyingError))
        case .itemNotFound:
            self = .itemNotFound
        case .securityError(let status):
            self = .securityError(status)
        }
    }
}

extension EngineCredentialStoreError {

    /// The engine error for a public credential-store error: the same case and payload, with the
    /// underlying error bridged through `EngineAuthError.bridgeUnderlyingError(_:)`.
    init(_ error: KeychainStoreError) {
        switch error {
        case .configuration(let message):
            self = .configuration(message: message)
        case .unknown(let description, let underlyingError):
            self = .unknown(description, EngineAuthError.bridgeUnderlyingError(underlyingError))
        case .conversionError(let description, let underlyingError):
            self = .conversionError(description, EngineAuthError.bridgeUnderlyingError(underlyingError))
        case .codingError(let description, let underlyingError):
            self = .codingError(description, EngineAuthError.bridgeUnderlyingError(underlyingError))
        case .itemNotFound:
            self = .itemNotFound
        case .securityError(let status):
            self = .securityError(status)
        }
    }

    /// Runs `body`, rethrowing an `EngineCredentialStoreError` as the public `KeychainStoreError`. For
    /// engine code whose errors leave the plugin unconverted: `UserPoolAnalytics.init`, whose keychain
    /// failure `configure(using:)` has always thrown as it is.
    static func rethrowingPublicError<Value>(_ body: () throws -> Value) throws -> Value {
        do {
            return try body()
        } catch let error as EngineCredentialStoreError {
            throw KeychainStoreError(error)
        }
    }
}
