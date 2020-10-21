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
    case validation(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// An unknown error occurred
    case unknown(ErrorDescription, RecoverySuggestion, Error?)
}

extension CoreError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .listOperation(let description, _, _),
             .validation(let description, _, _),
             .unknown(let description, _, _):
            return description
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .listOperation(_, let recoverySuggestion, _),
             .validation(_, let recoverySuggestion, _),
             .unknown(_, let recoverySuggestion, _):
            return recoverySuggestion
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .listOperation(_, _, let underlyingError),
             .validation(_, _, let underlyingError),
             .unknown(_, _, let underlyingError):
            return underlyingError
        }
    }

    public init(
        errorDescription: ErrorDescription = "An unknown error occurred",
        recoverySuggestion: RecoverySuggestion = "See `underlyingError` for more details",
        error: Error
    ) {
        if let error = error as? Self {
            self = error
        } else {
            self = .unknown(errorDescription, recoverySuggestion, error)
        }
    }

}
