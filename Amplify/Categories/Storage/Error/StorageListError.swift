//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum StorageListError {
    case httpStatusError(ErrorDescription, RecoverySuggestion)
    case unknown(ErrorDescription, RecoverySuggestion)
    case identity(ErrorDescription, RecoverySuggestion)
}

extension StorageListError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .httpStatusError(let description, _),
             .unknown(let description, _),
             .identity(let description, _):
            return description
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .httpStatusError(_, let recoverySuggestion),
             .unknown(_, let recoverySuggestion),
             .identity(_, let recoverySuggestion):
            return recoverySuggestion
        }
    }
}
