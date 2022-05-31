//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import Security

public enum KeychainStoreError {

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

extension KeychainStoreError: AmplifyError {

    public init(
        errorDescription: ErrorDescription = "An unknown error occurred",
        recoverySuggestion: RecoverySuggestion = "(Ignored)",
        error: Error
    ) {
        if let error = error as? Self {
            self = error
        } else if error.isOperationCancelledError {
            self = .unknown("Operation cancelled", error)
        } else {
            self = .unknown(errorDescription, error)
        }
    }

    /// Error Description
    public var errorDescription: ErrorDescription {
        switch self {
        case .conversionError(let errorDescription, _), .codingError(let errorDescription, _):
            return errorDescription
        case .securityError(let status):
            return "Keychain error occurred with status: \(status)"
        case .unknown(let errorDescription, _):
            return "Unexpected error occurred with message: \(errorDescription)"
        case .itemNotFound:
            return "Unable to find the keychain item"
        case .configuration(let message):
            return message
        }
    }

    /// Recovery Suggestion
    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .unknown, .conversionError, .securityError, .itemNotFound, .codingError, .configuration:
            return AmplifyErrorMessages.shouldNotHappenReportBugToAWS()
        }
    }

    /// Underlying Error
    public var underlyingError: Error? {
        switch self {
        case .conversionError(_, let error), .codingError(_, let error), .unknown(_, let error):
            return error
        default:
            return nil
        }
    }

}

extension KeychainStoreError: Equatable {
    public static func == (lhs: KeychainStoreError, rhs: KeychainStoreError) -> Bool {
        switch (lhs, rhs) {
        case (.configuration, .configuration):
            return true
        case (.unknown, .unknown):
            return true
        case (.conversionError, .conversionError):
            return true
        case (.codingError, codingError):
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
