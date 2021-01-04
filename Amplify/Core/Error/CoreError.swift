//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Errors associated with operations provided by Amplify
public enum CoreError {

    /// A related operation performed on `List` resulted in an error.
    case listOperation(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// A client side validation error occured.
    case clientValidation(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// An unknown error occurred
    case unknown(ErrorDescription, Error? = nil)
}

extension CoreError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .listOperation(let errorDescription, _, _),
             .clientValidation(let errorDescription, _, _):
            return errorDescription
        case .unknown(let errorDescription, _):
            return "Unexpected error occurred with message: \(errorDescription)"
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .listOperation(_, let recoverySuggestion, _),
             .clientValidation(_, let recoverySuggestion, _):
            return recoverySuggestion
        case .unknown:
            return AmplifyErrorMessages.shouldNotHappenReportBugToAWS()
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .listOperation(_, _, let underlyingError),
             .clientValidation(_, _, let underlyingError),
             .unknown(_, let underlyingError):
            return underlyingError
        }
    }

    public init(
        errorDescription: ErrorDescription = "An unknown error occurred",
        recoverySuggestion: RecoverySuggestion = "(Ignored)",
        error: Error
    ) {
        if let error = error as? Self {
            self = error
        } else {
            self = .unknown(errorDescription, error)
        }
    }

}
