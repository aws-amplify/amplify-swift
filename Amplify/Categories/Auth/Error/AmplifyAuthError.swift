//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// TODO: Rename to AuthError - #172336364
public enum AmplifyAuthError {
    case configuration(ErrorDescription, RecoverySuggestion, Error? = nil)
    case service(ErrorDescription, RecoverySuggestion, Error? = nil)
    case unknown(ErrorDescription, Error? = nil)
    case validation(Field, ErrorDescription, RecoverySuggestion, Error? = nil)
    case notAuthorized(ErrorDescription, RecoverySuggestion, Error? = nil)
    case invalidState(ErrorDescription, RecoverySuggestion, Error? = nil)
}

extension AmplifyAuthError: AmplifyError {

    public var underlyingError: Error? {
        switch self {
        case .configuration(_, _, let underlyingError),
             .service(_, _, let underlyingError),
             .unknown(_, let underlyingError),
             .validation(_, _, _, let underlyingError),
             .notAuthorized(_, _, let underlyingError),
             .invalidState(_, _, let underlyingError):
            return underlyingError
        }
    }

    public var errorDescription: ErrorDescription {
        switch self {
        case .configuration(let errorDescription, _, _),
             .service(let errorDescription, _, _),
             .validation(_, let errorDescription, _, _),
             .notAuthorized(let errorDescription, _, _),
             .invalidState(let errorDescription, _, _):
            return errorDescription
        case .unknown(let errorDescription, _):
            return "Unexpected error occurred with message: \(errorDescription)"
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .configuration(_, let recoverySuggestion, _),
             .service(_, let recoverySuggestion, _),
             .validation(_, _, let recoverySuggestion, _),
             .notAuthorized(_, let recoverySuggestion, _),
             .invalidState(_, let recoverySuggestion, _):
            return recoverySuggestion
        case .unknown:
            return AmplifyErrorMessages.shouldNotHappenReportBugToAWS()
        }
    }
}
