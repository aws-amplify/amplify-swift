//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Errors specific to the API Category
public enum APIError {

    /// An unknown error
    case unknown(ErrorDescription, RecoverySuggestion)

    /// The configuration for a particular API was invalid
    case invalidConfiguration(ErrorDescription, RecoverySuggestion)

    /// The URL in a request was invalid or missing
    case invalidURL(ErrorDescription, RecoverySuggestion)

    /// An in-process operation encountered a processing error. In addition to the
    /// description and recovery suggestion, an `operationError` will also contain the
    /// underlying error propagated by the system.
    case operationError(ErrorDescription, RecoverySuggestion, Error)

}

extension APIError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .unknown(let errorDescription, _):
            return errorDescription

        case .invalidConfiguration(let errorDescription, _):
            return errorDescription

        case .invalidURL(let errorDescription, _):
            return errorDescription

        case .operationError(let errorDescription, _, _):
            return errorDescription
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .unknown(_, let recoverySuggestion):
            return recoverySuggestion

        case .invalidConfiguration(_, let recoverySuggestion):
            return recoverySuggestion

        case .invalidURL(_, let recoverySuggestion):
            return recoverySuggestion

        case .operationError(_, let recoverySuggestion, _):
            return recoverySuggestion
        }
    }
}
