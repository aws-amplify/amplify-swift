//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// Represents domain-specific errors within the AmplifyCloudWatchLoggingClient subsystem.
@_spi(AmplifyExperimental)
public enum CloudWatchLoggingError: AmplifyError {
    /// Local file I/O or rotation error.
    case storage(ErrorDescription, RecoverySuggestion, Error? = nil)
    /// CloudWatch API call failed.
    case service(ErrorDescription, RecoverySuggestion, Error? = nil)
    /// Configuration error.
    case configuration(ErrorDescription, RecoverySuggestion, Error? = nil)
    /// Catch-all.
    case unknown(ErrorDescription, RecoverySuggestion, Error? = nil)

    public var errorDescription: ErrorDescription {
        switch self {
        case .storage(let description, _, _),
             .service(let description, _, _),
             .configuration(let description, _, _),
             .unknown(let description, _, _):
            return description
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .storage(_, let suggestion, _),
             .service(_, let suggestion, _),
             .configuration(_, let suggestion, _),
             .unknown(_, let suggestion, _):
            return suggestion
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .storage(_, _, let error),
             .service(_, _, let error),
             .configuration(_, _, let error),
             .unknown(_, _, let error):
            return error
        }
    }

    public init(
        errorDescription: ErrorDescription,
        recoverySuggestion: RecoverySuggestion,
        error: Error?
    ) {
        if let error = error as? Self {
            self = error
        } else {
            self = .unknown(errorDescription, recoverySuggestion, error)
        }
    }

    static func from(_ error: Error) -> CloudWatchLoggingError {
        if let loggingError = error as? CloudWatchLoggingError {
            return loggingError
        }
        return .unknown(
            "An unknown error occurred",
            defaultRecoverySuggestion,
            error
        )
    }
}
