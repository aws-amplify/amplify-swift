//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Errors specific to the API Category
public enum APIError {

    /// An unknown error
    case unknown(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// The configuration for a particular API was invalid
    case invalidConfiguration(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// The URL in a request was invalid or missing
    case invalidURL(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// An in-process operation encountered a processing error
    case operationError(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// An error to encapsulate an error received by a dependent plugin
    case pluginError(AmplifyError)
}

extension APIError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .unknown(let errorDescription, _, _):
            return "Unexpected error occurred with message: \(errorDescription)"

        case .invalidConfiguration(let errorDescription, _, _):
            return errorDescription

        case .invalidURL(let errorDescription, _, _):
            return errorDescription

        case .operationError(let errorDescription, _, _):
            return errorDescription

        case .pluginError(let error):
            return error.errorDescription
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .unknown(_, let recoverySuggestion, _):
            return """
            \(recoverySuggestion)
            
            This should never happen. There is a possibility that there is a bug if this error persists.
            Please take a look at https://github.com/aws-amplify/amplify-ios/issues to see if there are any
            existing issues that match your scenario, and file an issue with the details of the bug if there isn't.
            """

        case .invalidConfiguration(_, let recoverySuggestion, _):
            return recoverySuggestion

        case .invalidURL(_, let recoverySuggestion, _):
            return recoverySuggestion

        case .operationError(_, let recoverySuggestion, _):
            return recoverySuggestion

        case .pluginError(let error):
            return error.recoverySuggestion
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .unknown(_, _, let error):
            return error
        case .invalidConfiguration(_, _, let error):
            return error
        case .invalidURL(_, _, let error):
            return error
        case .operationError(_, _, let error):
            return error
        case .pluginError(let error):
            return error
        }
    }
}
