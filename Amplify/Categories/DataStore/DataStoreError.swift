//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// MARK: - Enum

public enum DataStoreError: Error {
    case configuration(ErrorDescription, RecoverySuggestion, Error? = nil)
    case invalidDatabase(Error? = nil)
    case invalidOperation(causedBy: Error? = nil)
}

// MARK: - AmplifyError

extension DataStoreError: AmplifyError {

    public var errorDescription: ErrorDescription {
        switch self {
        case .configuration(let errorDescription, _, _):
            return errorDescription
        case .invalidDatabase:
            return ""
        case .invalidOperation(let causedBy):
            return causedBy?.localizedDescription ?? ""
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .configuration(_, let recoverySuggestion, _):
            return recoverySuggestion
        case .invalidDatabase:
            return ""
        case .invalidOperation(let causedBy):
            return causedBy?.localizedDescription ?? ""
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .configuration(_, _, let underlyingError):
            return underlyingError
        case .invalidDatabase(let underlyingError):
            return underlyingError
        case .invalidOperation(let underlyingError):
            return underlyingError
        }
    }
}
