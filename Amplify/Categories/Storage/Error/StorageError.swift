//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
public enum StorageError {
    case accessDenied(ErrorDescription, RecoverySuggestion)
    case authError(ErrorDescription, RecoverySuggestion)
    case httpStatusError(Int, RecoverySuggestion)
    case keyNotFound(Key, ErrorDescription, RecoverySuggestion)
    case localFileNotFound(ErrorDescription, RecoverySuggestion)
    case service(ErrorDescription, RecoverySuggestion)
    case unknown(ErrorDescription)
    case validation(Field, ErrorDescription, RecoverySuggestion)
}

extension StorageError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .accessDenied(let errorDescription, _),
             .authError(let errorDescription, _),
             .service(let errorDescription, _),
             .localFileNotFound(let errorDescription, _):
            return errorDescription
        case .httpStatusError(let statusCode, _):
            return "The HTTP response status code is [\(statusCode)]."
        case .keyNotFound(let key, let errorDescription, _):
            return "The key '\(key)' could not be found with message: \(errorDescription)."
        case .unknown(let errorDescription):
            return "Unexpected error occurred with message: \(errorDescription)"
        case .validation(let field, let errorDescription, _):
            return "There is a client side validation error for the field [\(field)] with message: \(errorDescription)"
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .accessDenied(_, let recoverySuggestion),
             .authError(_, let recoverySuggestion),
             .localFileNotFound(_, let recoverySuggestion),
             .service(_, let recoverySuggestion),
             .validation(_, _, let recoverySuggestion):
            return recoverySuggestion
        case .httpStatusError(_, let recoverySuggestion):
            return """
                   \(recoverySuggestion).
                   For more information on HTTP status codes, take a look at
                   https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
                   """
        case .keyNotFound(_, _, let recoverySuggestion):
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
}
