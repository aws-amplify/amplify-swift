//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Amplify error raised in the Auth category.
public enum AuthError {

    /// Caused by issue in the way auth category is configured
    case configuration(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// Caused by some error in the underlying service. Check the associated error for more details.
    case service(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// Caused by an unknown reason
    case unknown(ErrorDescription, Error? = nil)

    /// Caused when one of the input field is invalid
    case validation(Field, ErrorDescription, RecoverySuggestion, Error? = nil)

    /// Caused when the current session is not authorized to perform an operation
    case notAuthorized(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// Caused when an operation is not valid with the current state of Auth category
    case invalidState(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// Caused when an operation needs the user to be in signedIn state
    case signedOut(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// Caused when a session is expired and needs the user to be re-authenticated
    case sessionExpired(ErrorDescription, RecoverySuggestion, Error? = nil)
}

extension AuthError: AmplifyError {

    public var underlyingError: Error? {
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

//    public var errorDescription: ErrorDescription? {
//        switch self {
//        case .configuration(let errorDescription, _, _),
//             .service(let errorDescription, _, _),
//             .validation(_, let errorDescription, _, _),
//             .notAuthorized(let errorDescription, _, _),
//             .signedOut(let errorDescription, _, _),
//             .sessionExpired(let errorDescription, _, _),
//             .invalidState(let errorDescription, _, _):
//            return errorDescription
//        case .unknown(let errorDescription, _):
//            return "Unexpected error occurred with message: \(errorDescription)"
//        }
//    }

    public var recoverySuggestion: RecoverySuggestion {
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
            return AmplifyErrorMessages.shouldNotHappenReportBugToAWSWithoutLineInfo()
        }
    }

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

extension AuthError {
    public var errorDescription: ErrorDescription? {
        var message  = ""
        switch self {
        case .configuration(let errorDescription, let recoverySuggestion, let error):
            message = "Configuration error: \(errorDescription). \(recoverySuggestion)"
            if let error = error {
                message += " Underlying error: \(error.localizedDescription)"
            }
        case .service(let errorDescription, let recoverySuggestion, let error):
            message = "Service error: \(errorDescription). \(recoverySuggestion)"
            if let error = error {
                message += " Underlying error: \(error.localizedDescription)"
            }
        case .unknown(let errorDescription, let error):
            message = "Unknown error: \(errorDescription)"
            if let error = error {
                message += " Underlying error: \(error.localizedDescription)"
            }
        case .validation(let field, let errorDescription, let recoverySuggestion, let error):
            message = "Validation error for field: \(field). \(errorDescription). \(recoverySuggestion)"
            if let error = error {
                message += " Underlying error: \(error.localizedDescription)"
            }
        case .notAuthorized(let errorDescription, let recoverySuggestion, let error):
            message = "Not authorized error: \(errorDescription). \(recoverySuggestion)"
            if let error = error {
                message += " Underlying error: \(error.localizedDescription)"
            }
        case .signedOut(let errorDescription, let recoverySuggestion, let error):
            message = "Signed out: \(errorDescription). \(recoverySuggestion)"
            if let error = error {
                message += " Underlying error: \(error.localizedDescription)"
            }
        case .sessionExpired(let errorDescription, let recoverySuggestion, let error):
            message = "Session expired: \(errorDescription). \(recoverySuggestion)"
            if let error = error {
                message += " Underlying error: \(error.localizedDescription)"
            }
        case .invalidState(let errorDescription, let recoverySuggestion, let error):
            message = "Invalid state: \(errorDescription). \(recoverySuggestion)"
            if let error = error {
                message += " Underlying error: \(error.localizedDescription)"
            }
        }
        return "\(String(describing: Self.self)): \(message)"
    }
}
