//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public enum RecordCacheError {
    /// Storage error - database operations failed
    case storage(ErrorDescription, RecoverySuggestion, Error? = nil)
    
    /// Cache limit exceeded - no space for new records
    case limitExceeded(ErrorDescription, RecoverySuggestion, Error? = nil)
    
    /// Network error - failed to send records
    case network(ErrorDescription, RecoverySuggestion, Error? = nil)
    
    /// Unknown error
    case unknown(ErrorDescription, Error? = nil)
}

extension RecordCacheError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .storage(let description, _, _),
             .limitExceeded(let description, _, _),
             .network(let description, _, _):
            return description
        case .unknown(let description, _):
            return "Unexpected error occurred: \(description)"
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .storage(_, let suggestion, _),
             .limitExceeded(_, let suggestion, _),
             .network(_, let suggestion, _):
            return suggestion
        case .unknown:
            return "Please report this issue"
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .storage(_, _, let error),
             .limitExceeded(_, _, let error),
             .network(_, _, let error),
             .unknown(_, let error):
            return error
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
