//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation

/// Top-level error type for Event Enrichment operations.
public enum EventEnrichmentError {
    /// An operation was attempted on a closed client.
    case clientClosed(ErrorDescription, RecoverySuggestion, Error? = nil)
    /// An error that doesn't fall into the known categories above.
    case unknown(ErrorDescription, RecoverySuggestion, Error? = nil)
}

extension EventEnrichmentError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .clientClosed(let description, _, _),
             .unknown(let description, _, _):
            return description
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .clientClosed(_, let suggestion, _),
             .unknown(_, let suggestion, _):
            return suggestion
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .clientClosed(_, _, let error),
             .unknown(_, _, let error):
            return error
        }
    }

    public init(
        errorDescription: ErrorDescription,
        recoverySuggestion: RecoverySuggestion,
        error: Error?
    ) {
        self = .unknown(errorDescription, recoverySuggestion, error)
    }
}
