//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// The engine's copy of `Amplify.AuthError` (`Amplify/Categories/Auth/Error/AuthError.swift`).
///
/// It mirrors `AuthError` case for case and payload for payload, in the same case order, so the
/// plugin's `AuthError(_:)` / `EngineAuthError(_:)` conversions are one exhaustive switch each way.
/// `Field` is `String`, as it is in Amplify.
///
/// `errorDescription`, `recoverySuggestion`, `underlyingError` and `==` are copied line for line.
/// `==` compares the case only, and `.unknown` is never equal to anything. The state machine suppresses
/// transitions whose states compare equal, so this is load-bearing. `debugDescription` prints the
/// literal name `AuthError`, so log lines that interpolate an engine error read as they do today.
package enum EngineAuthError {

    /// Caused by issue in the way auth category is configured
    case configuration(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// Caused by some error in the underlying service. Check the associated error for more details.
    case service(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// Caused by an unknown reason
    case unknown(ErrorDescription, Error? = nil)

    /// Caused when one of the input field is invalid
    case validation(String, ErrorDescription, RecoverySuggestion, Error? = nil)

    /// Caused when the current session is not authorized to perform an operation
    case notAuthorized(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// Caused when an operation is not valid with the current state of Auth category
    case invalidState(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// Caused when an operation needs the user to be in signedIn state
    case signedOut(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// Caused when a session is expired and needs the user to be re-authenticated
    case sessionExpired(ErrorDescription, RecoverySuggestion, Error? = nil)
}

extension EngineAuthError: Error {

    package var underlyingError: Error? {
        switch self {
        case .configuration(_, _, let underlyingError),
             .service(_, _, let underlyingError),
             .unknown(_, let underlyingError),
             .validation(_, _, _, let underlyingError),
             .notAuthorized(_, _, let underlyingError),
             .sessionExpired(_, _, let underlyingError),
             .signedOut(_, _, let underlyingError),
             .invalidState(_, _, let underlyingError):
            return underlyingError
        }
    }

    package var errorDescription: ErrorDescription {
        switch self {
        case .configuration(let errorDescription, _, _),
             .service(let errorDescription, _, _),
             .validation(_, let errorDescription, _, _),
             .notAuthorized(let errorDescription, _, _),
             .signedOut(let errorDescription, _, _),
             .sessionExpired(let errorDescription, _, _),
             .invalidState(let errorDescription, _, _):
            return errorDescription
        case .unknown(let errorDescription, _):
            return "Unexpected error occurred with message: \(errorDescription)"
        }
    }

    package var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .configuration(_, let recoverySuggestion, _),
             .service(_, let recoverySuggestion, _),
             .validation(_, _, let recoverySuggestion, _),
             .notAuthorized(_, let recoverySuggestion, _),
             .signedOut(_, let recoverySuggestion, _),
             .sessionExpired(_, let recoverySuggestion, _),
             .invalidState(_, let recoverySuggestion, _):
            return recoverySuggestion
        case .unknown:
            return EngineErrorMessages.shouldNotHappenReportBugToAWSWithoutLineInfo()
        }
    }
}

extension EngineAuthError: Equatable {
    package static func == (lhs: EngineAuthError, rhs: EngineAuthError) -> Bool {
        switch (lhs, rhs) {
        case (.configuration, .configuration),
            (.service, .service),
            (.validation, .validation),
            (.notAuthorized, .notAuthorized),
            (.signedOut, .signedOut),
            (.sessionExpired, .sessionExpired),
            (.invalidState, .invalidState):
            return true
        default:
            return false
        }
    }
}

extension EngineAuthError: CustomDebugStringConvertible {

    /// `AmplifyError.debugDescription` (`Amplify/Core/Support/AmplifyError.swift:65-83`) with the legacy
    /// type name as a literal, never `type(of: self)`.
    ///
    /// Amplify's version prints an underlying `AmplifyError` through its `debugDescription` and anything
    /// else through `"\(underlyingError)"`. The engine cannot name `Amplify.AmplifyError`, so it prints an
    /// underlying `EngineAuthError` through its `debugDescription` and everything else through
    /// interpolation. The output is the same: an Amplify error without `CustomStringConvertible`
    /// (`AuthError`, `KeychainStoreError`) interpolates as its `debugDescription`.
    /// `EngineAuthErrorTests` checks both paths against `AuthError`.
    package var debugDescription: String {
        var components = ["AuthError: \(errorDescription)"]

        if !recoverySuggestion.isEmpty {
            components.append("Recovery suggestion: \(recoverySuggestion)")
        }

        if let underlyingError {
            if let underlyingEngineError = underlyingError as? EngineAuthError {
                components.append("Caused by:\n\(underlyingEngineError.debugDescription)")
            } else {
                components.append("Caused by:\n\(underlyingError)")
            }
        }

        return components.joined(separator: "\n")
    }
}

/// A type that can be represented as an `EngineAuthError`: the engine's `AuthErrorConvertible`.
///
/// The plugin converts through `AuthError(converting:)`, which tries `AuthErrorConvertible` first and
/// then this protocol.
///
/// - Note: `Sendable` because these errors are thrown out of actor-isolated auth work.
package protocol EngineAuthErrorConvertible: Sendable {
    var engineError: EngineAuthError { get }
}

extension EngineAuthError: EngineAuthErrorConvertible {
    package var engineError: EngineAuthError {
        return self
    }
}
