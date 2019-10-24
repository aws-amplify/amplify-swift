//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum APIError {
    case unknown(ErrorDescription, RecoverySuggestion)
    case invalidURL(ErrorDescription, RecoverySuggestion)
}

extension APIError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .unknown(let errorDescription, _):
            return errorDescription
        case .invalidURL(let errorDescription, _):
            return errorDescription
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .unknown(_, let recoverySuggestion):
            return recoverySuggestion
        case .invalidURL(_, let recoverySuggestion):
            return recoverySuggestion
        }
    }
}
