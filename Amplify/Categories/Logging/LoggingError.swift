//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public enum LoggingError {

    /// <#Description#>
    case configuration(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// <#Description#>
    case unknown(ErrorDescription, Error?)
}

extension LoggingError: AmplifyError {

    /// <#Description#>
    public var errorDescription: ErrorDescription {
        switch self {
        case .configuration(let errorDescription, _, _):
            return errorDescription
        case .unknown(let errorDescription, _):
            return "Unexpected error occurred with message: \(errorDescription)"
        }
    }

    /// <#Description#>
    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .configuration(_, let recoverySuggestion, _):
            return recoverySuggestion
        case .unknown:
            return AmplifyErrorMessages.shouldNotHappenReportBugToAWS()
        }
    }

    /// <#Description#>
    public var underlyingError: Error? {
        switch self {
        case .configuration(_, _, let underlyingError),
             .unknown(_, let underlyingError):
            return underlyingError
        }
    }

    /// <#Description#>
    /// - Parameters:
    ///   - errorDescription: <#errorDescription description#>
    ///   - recoverySuggestion: <#recoverySuggestion description#>
    ///   - error: <#error description#>
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
