//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Errors associated with configuring and inspecting Amplify Categories
public enum HubError {

    /// <#Description#>
    case configuration(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// <#Description#>
    case unknownError(ErrorDescription, RecoverySuggestion, Error? = nil)
}

extension HubError: AmplifyError {

    /// <#Description#>
    public var errorDescription: ErrorDescription {
        switch self {
        case .configuration(let description, _, _),
             .unknownError(let description, _, _):
            return description
        }
    }

    /// <#Description#>
    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .configuration(_, let recoverySuggestion, _),
             .unknownError(_, let recoverySuggestion, _):
            return recoverySuggestion
        }
    }

    /// <#Description#>
    public var underlyingError: Error? {
        switch self {
        case .configuration(_, _, let underlyingError),
             .unknownError(_, _, let underlyingError):
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
        recoverySuggestion: RecoverySuggestion = "See `underlyingError` for more details",
        error: Error
    ) {
        if let error = error as? Self {
            self = error
        } else {
            self = .unknownError(errorDescription, recoverySuggestion, error)
        }
    }

}
