//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Amplify error raised in the Auth category.
public struct AuthError {

    public let field: Field?
    public let errorDescription: ErrorDescription
    public let recoverySuggestion: RecoverySuggestion
    public let underlyingError: Error?
    public let type: String
    
    private init(type: String, errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion, error: Error?, field: Field? = nil) {
        self.type = type
        self.field = field
        self.errorDescription = errorDescription
        self.recoverySuggestion = recoverySuggestion
        self.underlyingError = error
    }
    
    /// Caused by issue in the way auth category is configured
    public static func configuration(_ errorDescription: ErrorDescription, _ recoverySuggestion: RecoverySuggestion = "", _ error: Error? = nil) -> AuthError {
        return AuthError(type: AuthError.configurationError, errorDescription: errorDescription, recoverySuggestion: recoverySuggestion, error: error)
    }
    
    /// Caused by some error in the underlying service. Check the associated error for more details.
    public static func service(_ errorDescription: ErrorDescription, _ recoverySuggestion: RecoverySuggestion = "", _ error: Error? = nil) -> AuthError {
        return AuthError(type: AuthError.serviceError, errorDescription: errorDescription, recoverySuggestion: recoverySuggestion, error: error)
    }
    
    /// Caused by an unknown reason
    public static func unknown(_ errorDescription: ErrorDescription, _ error: Error? = nil) -> AuthError {
        return AuthError(type: AuthError.unknownError, errorDescription: errorDescription, recoverySuggestion: "", error: error)
    }
    
    /// Caused when one of the input field is invalid
    public static func validation(_ field: Field, _ errorDescription: ErrorDescription, _ recoverySuggestion: RecoverySuggestion = "", _ error: Error? = nil) -> AuthError {
        return AuthError(type: AuthError.validationError, errorDescription: errorDescription, recoverySuggestion: recoverySuggestion, error: error, field: field)
    }
    
    /// Caused when the current session is not authorized to perform an operation
    public static func notAuthorized(_ errorDescription: ErrorDescription, _ recoverySuggestion: RecoverySuggestion = "", _ error: Error? = nil) -> AuthError {
        return AuthError(type: AuthError.notAuthorizedError, errorDescription: errorDescription, recoverySuggestion: recoverySuggestion, error: error)
    }
    
    /// Caused when an operation is not valid with the current state of Auth category
    public static func invalidState(_ errorDescription: ErrorDescription, _ recoverySuggestion: RecoverySuggestion = "", _ error: Error? = nil) -> AuthError {
        return AuthError(type: AuthError.invalidStateError, errorDescription: errorDescription, recoverySuggestion: recoverySuggestion, error: error)
    }
    
    /// Caused when an operation needs the user to be in signedIn state
    public static func signedOut(_ errorDescription: ErrorDescription, _ recoverySuggestion: RecoverySuggestion = "", _ error: Error? = nil) -> AuthError {
        return AuthError(type: AuthError.signedOutError, errorDescription: errorDescription, recoverySuggestion: recoverySuggestion, error: error)
    }
    
    /// Caused when a session is expired and needs the user to be re-authenticated
    public static func sessionExpired(_ errorDescription: ErrorDescription, _ recoverySuggestion: RecoverySuggestion = "", _ error: Error? = nil) -> AuthError {
        return AuthError(type: AuthError.sessionExpiredError, errorDescription: errorDescription, recoverySuggestion: recoverySuggestion, error: error)
    }
}

extension AuthError {
    public static let configurationError = "AuthError.Configuration"
    public static let serviceError = "AuthError.Service"
    public static let validationError = "AuthError.Validation"
    public static let notAuthorizedError = "AuthError.notAuthorized"
    public static let invalidStateError = "AuthError.InvalidState"
    public static let signedOutError = "AuthError.SignedOut"
    public static let sessionExpiredError = "AuthError.SessionExpired"
    public static let unknownError = "AuthError.Unknown"
}

extension AuthError: AmplifyError {
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
}

extension AuthError: Equatable {
    public static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        return lhs.type == rhs.type
    }
}
