//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum StorageError {
    case accessDenied(ErrorDescription, RecoverySuggestion, Error?)
    case authError(ErrorDescription, RecoverySuggestion, Error?)
    case httpStatusError(Int, RecoverySuggestion, Error?)
    case keyNotFound(Key, ErrorDescription, RecoverySuggestion, Error?)
    case localFileNotFound(ErrorDescription, RecoverySuggestion, Error?)
    case service(ErrorDescription, RecoverySuggestion, Error?)
    case unknown(ErrorDescription, Error?)
    case validation(Field, ErrorDescription, RecoverySuggestion, Error?)
}

extension StorageError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .accessDenied(let errorDescription, _, _),
             .authError(let errorDescription, _, _),
             .service(let errorDescription, _, _),
             .localFileNotFound(let errorDescription, _, _):
            return errorDescription
        case .httpStatusError(let statusCode, _, _):
            return "The HTTP response status code is [\(statusCode)]."
        case .keyNotFound(let key, let errorDescription, _, _):
            return "The key '\(key)' could not be found with message: \(errorDescription)."
        case .unknown(let errorDescription, _):
            return "Unexpected error occurred with message: \(errorDescription)"
        case .validation(let field, let errorDescription, _, _):
            return "There is a client side validation error for the field [\(field)] with message: \(errorDescription)"
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .accessDenied(_, let recoverySuggestion, _),
             .authError(_, let recoverySuggestion, _),
             .localFileNotFound(_, let recoverySuggestion, _),
             .service(_, let recoverySuggestion, _),
             .validation(_, _, let recoverySuggestion, _):
            return recoverySuggestion
        case .httpStatusError(_, let recoverySuggestion, _):
            return """
                   \(recoverySuggestion).
                   For more information on HTTP status codes, take a look at
                   https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
                   """
        case .keyNotFound(_, _, let recoverySuggestion, _):
            return """
                   \(recoverySuggestion)
                   The object for key in the public access level should exist under the public folder as public/<key>.
                   When looking for the key in protected or private access level, it will be under its respective folder
                   such as 'protected/<targetIdentityId>/<key>' or 'private/<targetIdentityId>/<key>'.
                   """
        case .unknown:
            return """
                This should never happen. There is a possibility that there is bug if this error persists.
                Please take a look at https://github.com/aws-amplify/amplify-ios/issues to see if there are any
                existing issues that match your scenario, and file an issue with the details of the bug if there isn't.
                """
        }
    }

    public var underlyingError: Error? {
        switch self {
            case .accessDenied(_, _, let error):
                return error
            case .authError(_, _, let error):
                return error
            case .httpStatusError(_, _, let error):
                return error
            case .keyNotFound(_, _, _, let error):
                return error
            case .localFileNotFound(_, _, let error):
                return error
            case .service(_, _, let error):
                return error
            case .unknown(_, let error):
                return error
            case .validation(_, _, _, let error):
                return error
        }
    }
}
