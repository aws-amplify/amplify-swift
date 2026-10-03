//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation
import InternalAmplifyKeychain

/// The engine's copy of `AWSPluginsCore.KeychainStoreError`
/// (`AmplifyPlugins/Core/AWSPluginsCore/Keychain/KeychainStoreError.swift`), the error the credential store,
/// its actions and the legacy-store migration throw.
///
/// It mirrors `KeychainStoreError` case for case and payload for payload, in the same case order, so the
/// plugin's conversions are one exhaustive switch each way.
///
/// - `errorDescription`, `recoverySuggestion`, `underlyingError` and `==` are copied line for line. `==`
///   compares the case only. The state machine suppresses transitions whose states compare equal, so this
///   is load-bearing.
/// - The recovery text that embeds a source location passes `KeychainStoreError`'s own location as
///   literals, so the text an app sees, and the log lines that print it, are unchanged.
///   `EngineCredentialStoreErrorTests` compares every case with `KeychainStoreError`.
/// - `debugDescription` prints the literal name `KeychainStoreError`, never `type(of: self)`.
package enum EngineCredentialStoreError {

    /// Caused by a configuration
    case configuration(message: String)

    /// Caused by an unknown reason
    case unknown(ErrorDescription, Error? = nil)

    /// Caused by trying to convert String to Data or vice-versa
    case conversionError(ErrorDescription, Error? = nil)

    /// Caused by trying encoding/decoding
    case codingError(ErrorDescription, Error? = nil)

    /// Unable to find the keychain item
    case itemNotFound

    /// Caused trying to perform a keychain operation, examples, missing entitlements, missing required attributes, etc
    case securityError(OSStatus)
}

extension EngineCredentialStoreError: Error {

    /// Error Description
    package var errorDescription: ErrorDescription {
        switch self {
        case .conversionError(let errorDescription, _), .codingError(let errorDescription, _):
            return errorDescription
        case .securityError(let status):
            let keychainStatus = KeychainStatus(status: status)
            return keychainStatus.description
        case .unknown(let errorDescription, _):
            return "Unexpected error occurred with message: \(errorDescription)"
        case .itemNotFound:
            return "Unable to find the keychain item"
        case .configuration(let message):
            return message
        }
    }

    /// Recovery Suggestion
    package var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .itemNotFound:
            // If a keychain item is not found, there is no recovery suggestion to suggest
            return ""
        case .securityError(let status):
            let keychainStatus = KeychainStatus(status: status)
#if os(macOS)
            // If its Missing entitlement error on macOS
            guard case .missingEntitlement = keychainStatus else {
                return Self.shouldNotHappenReportBugToAWS(line: 78)
            }
            return """
            To use Auth in a macOS project, you'll need to enable the Keychain Sharing capability.
            This capability is required because Auth uses the Data Protection Keychain on macOS as
            a platform best practice. See TN3137: macOS keychain APIs and implementations for more
            information on how Keychain works on macOS and the Keychain Sharing entitlement.
            For more information on adding capabilities to your application, see Xcode Capabilities.
            """
#else
            return Self.shouldNotHappenReportBugToAWS(line: 88)
#endif
        case .unknown, .conversionError, .codingError, .configuration:
            return Self.shouldNotHappenReportBugToAWS(line: 91)
        }
    }

    /// Underlying Error
    package var underlyingError: Error? {
        switch self {
        case .conversionError(_, let error), .codingError(_, let error), .unknown(_, let error):
            return error
        default:
            return nil
        }
    }

    /// `AmplifyErrorMessages.shouldNotHappenReportBugToAWS()` as `KeychainStoreError.recoverySuggestion`
    /// calls it at `line`, so the embedded location reads as it always has. The lines are those of the
    /// three calls in `KeychainStoreError.swift`.
    private static func shouldNotHappenReportBugToAWS(line: UInt) -> String {
        EngineErrorMessages.shouldNotHappenReportBugToAWS(
            file: "AWSPluginsCore/KeychainStoreError.swift",
            function: "recoverySuggestion",
            line: line
        )
    }
}

extension EngineCredentialStoreError: Equatable {
    package static func == (lhs: EngineCredentialStoreError, rhs: EngineCredentialStoreError) -> Bool {
        switch (lhs, rhs) {
        case (.configuration, .configuration):
            return true
        case (.unknown, .unknown):
            return true
        case (.conversionError, .conversionError):
            return true
        case (.codingError, .codingError):
            return true
        case (.itemNotFound, .itemNotFound):
            return true
        case (.securityError, .securityError):
            return true
        default:
            return false
        }
    }
}

extension EngineCredentialStoreError: CustomDebugStringConvertible {

    /// `AmplifyError.debugDescription` (`Amplify/Core/Support/AmplifyError.swift:65-83`) with the legacy
    /// type name as a literal, never `type(of: self)`.
    ///
    /// Amplify's version prints an underlying `AmplifyError` through its `debugDescription` and anything
    /// else through `"\(underlyingError)"`. The engine cannot name `Amplify.AmplifyError`; an engine fork
    /// is printed through its `debugDescription`, and anything else through interpolation, which for an
    /// Amplify error without `CustomStringConvertible` is its `debugDescription` too.
    package var debugDescription: String {
        var components = ["KeychainStoreError: \(errorDescription)"]

        if !recoverySuggestion.isEmpty {
            components.append("Recovery suggestion: \(recoverySuggestion)")
        }

        if let underlyingError {
            if let underlyingEngineError = underlyingError as? EngineAuthError {
                components.append("Caused by:\n\(underlyingEngineError.debugDescription)")
            } else if let underlyingStoreError = underlyingError as? EngineCredentialStoreError {
                components.append("Caused by:\n\(underlyingStoreError.debugDescription)")
            } else {
                components.append("Caused by:\n\(underlyingError)")
            }
        }

        return components.joined(separator: "\n")
    }
}

extension EngineCredentialStoreError: EngineAuthErrorConvertible {

    /// Copied from `KeychainStoreError+AuthConvertible.swift`, which the plugin keeps for the public type.
    package var engineError: EngineAuthError {
        switch self {
        case .configuration(let message):
            return .configuration(message, recoverySuggestion)
        case .unknown(let errorDescription, let error):
            return .unknown(errorDescription, error)
        case .conversionError(let errorDescription, let error):
            return .configuration(errorDescription, recoverySuggestion, error)
        case .codingError(let errorDescription, let error):
            return .configuration(errorDescription, recoverySuggestion, error)
        case .itemNotFound:
            return .service(errorDescription, recoverySuggestion)
        case .securityError:
            return .service(errorDescription, recoverySuggestion)
        }
    }
}

package extension EngineCredentialStoreError {

    /// Maps a failure from the shared keychain implementation one-to-one onto the case
    /// `KeychainStoreError(_:)` reports for it.
    init(_ error: KeychainAccessError) {
        switch error {
        case .itemNotFound:
            self = .itemNotFound
        case .securityError(let status):
            self = .securityError(status)
        case .unknown(let errorDescription, let underlyingError):
            self = .unknown(errorDescription, underlyingError)
        }
    }

    /// Runs `body`, rethrowing a `KeychainAccessError` as the equivalent `EngineCredentialStoreError`. Any
    /// other error passes through unchanged. The copy of `KeychainStoreError.mapping(_:)`.
    static func mapping<Value>(_ body: () throws -> Value) throws -> Value {
        do {
            return try body()
        } catch let error as KeychainAccessError {
            throw EngineCredentialStoreError(error)
        }
    }
}
