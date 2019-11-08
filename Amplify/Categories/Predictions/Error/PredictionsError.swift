//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Error occured while using Prediction category
public enum PredictionsError {

    /// Access denied while executing the operation
    case accessDenied(ErrorDescription, RecoverySuggestion)
    case authError(ErrorDescription, RecoverySuggestion)
    case httpStatusError(Int, RecoverySuggestion)
    case networkError(ErrorDescription, RecoverySuggestion)
    case unknownError(ErrorDescription, RecoverySuggestion)
}

extension PredictionsError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .accessDenied(let errorDescription, _),
             .authError(let errorDescription, _):
            return errorDescription
        case .unknownError(let errorDescription):
            return "Unexpected error occurred with message: \(errorDescription)"
        case .networkError(let errorDescription):
            return "Network error occurred with message:\(errorDescription)"
        case .httpStatusError(let statusCode, _):
            return "The HTTP response status code is [\(statusCode)]."
        }

    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .accessDenied(_, let recoverySuggestion),
             .authError(_, let recoverySuggestion),
             .networkError(_, let recoverySuggestion):
            return recoverySuggestion

        case .httpStatusError(_, let recoverySuggestion):
            return """
            \(recoverySuggestion).
            For more information on HTTP status codes, take a look at
            https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
            """
        case .unknownError:
            return """
            This should never happen. There is a possibility that there is bug if this error persists.
            Please take a look at https://github.com/aws-amplify/amplify-ios/issues to see if there are any
            existing issues that match your scenario, and file an issue with the details of the bug if there isn't.
            """
        }
    }
}
