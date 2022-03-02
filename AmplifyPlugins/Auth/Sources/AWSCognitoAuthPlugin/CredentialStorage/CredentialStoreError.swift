//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import Security

enum CredentialStoreError {

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

extension CredentialStoreError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .configuration(let message):
            return .configuration(message,
                                  AmplifyErrorMessages.shouldNotHappenReportBugToAWS(),
                                  nil)
        case .unknown(let errorDescription, let error):
            return .unknown(errorDescription, error)
        case .conversionError(let errorDescription, let error):
            return .service(errorDescription,
                            AmplifyErrorMessages.shouldNotHappenReportBugToAWS(),
                            error)
        case .codingError(let errorDescription, let error):
            return .service(errorDescription,
                            AmplifyErrorMessages.shouldNotHappenReportBugToAWS(),
                            error)
        case .itemNotFound:
            return .service("Credential Store Item not found", "", nil)
        case .securityError(let oSStatus):
            return .service("Credential store security error with status: \(oSStatus)",
                            AmplifyErrorMessages.shouldNotHappenReportBugToAWS(),
                            nil)
        }
    }

}

extension CredentialStoreError: AmplifyError {

    init(
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
    var errorDescription: ErrorDescription {
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
    var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .unknown, .conversionError, .securityError, .itemNotFound, .codingError, .configuration:
            return AmplifyErrorMessages.shouldNotHappenReportBugToAWS()
        }
    }

    /// Underlying Error
    var underlyingError: Error? {
        switch self {
        case .conversionError(_, let error), .codingError(_, let error), .unknown(_, let error):
            return error
        default:
            return nil
        }
    }

}

extension CredentialStoreError: Equatable {
    static func == (lhs: CredentialStoreError, rhs: CredentialStoreError) -> Bool {
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
