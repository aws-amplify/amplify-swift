//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation

public enum FoundationBridgeError {
    case unknown(ErrorDescription, Error? = nil)
}

extension FoundationBridgeError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .unknown(let description, _):
            return "An unexpected error occurred with message: \(description)"
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .unknown:
            return
                "An unknown error occurred. Please check error description for details."
        }
    }

    public var underlyingError: (any Error)? {
        switch self {
        case .unknown(_, let error):
            return error
        }
    }

    public init(
        errorDescription: ErrorDescription = "An unknown error occurred",
        recoverySuggestion: RecoverySuggestion =
            "Please check error description for details.",
        error: (any Error)?
    ) {
        if let error = error as? Self {
            self = error
        } else {
            self = .unknown(errorDescription, error)
        }
    }
}
