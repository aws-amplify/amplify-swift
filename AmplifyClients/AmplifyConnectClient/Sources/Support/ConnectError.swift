//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation

/// Top-level error type for Connect Client operations.
public enum ConnectError {
    /// Configuration is invalid or missing required fields.
    case configuration(ErrorDescription, RecoverySuggestion, Error? = nil)
    /// Neither a token nor credentials could be resolved.
    case credentials(ErrorDescription, RecoverySuggestion, Error? = nil)
    /// The identify-user request failed.
    case service(ErrorDescription, RecoverySuggestion, Error? = nil)
    /// An error that doesn't fall into the known categories above.
    case unknown(ErrorDescription, RecoverySuggestion, Error? = nil)
}

extension ConnectError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .configuration(let description, _, _),
             .credentials(let description, _, _),
             .service(let description, _, _),
             .unknown(let description, _, _):
            return description
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .configuration(_, let suggestion, _),
             .credentials(_, let suggestion, _),
             .service(_, let suggestion, _),
             .unknown(_, let suggestion, _):
            return suggestion
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .configuration(_, _, let error),
             .credentials(_, _, let error),
             .service(_, _, let error),
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
