//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum LoggingError {
    case configuration(ErrorDescription, RecoverySuggestion, Error? = nil)
    case unknown(ErrorDescription, Error?)
}

extension LoggingError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .configuration(let errorDescription, _, _):
            return errorDescription
        case .unknown(let errorDescription, _):
            return "Unexpected error occurred with message: \(errorDescription)"
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .configuration(_, let recoverySuggestion, _):
            return recoverySuggestion
        case .unknown:
            return AmplifyErrorMessages.shouldNotHappenReportBugToAWS()
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .configuration(_, _, let underlyingError),
             .unknown(_, let underlyingError):
            return underlyingError
        }
    }
}
