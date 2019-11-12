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
    case decodingError(ErrorDescription, RecoverySuggestion)
    case invalidDatabase(path: String, Error? = nil)
    case invalidOperation(causedBy: Error? = nil)
    case nonUniqueResult(model: String)
}

// MARK: - AmplifyError

extension DataStoreError: AmplifyError {

    public var errorDescription: ErrorDescription {
        switch self {
        case .configuration(let errorDescription, _, _):
            return errorDescription
        case .decodingError(let errorDescription, _):
            return errorDescription
        case .invalidDatabase:
            return "Could not create a new database."
        case .invalidOperation(let causedBy):
            return causedBy?.localizedDescription ?? ""
        case .nonUniqueResult(let model):
            return "The result of the queried model of type \(model) return more than one result."
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .configuration(_, let recoverySuggestion, _):
            return recoverySuggestion
        case .decodingError(_, let recoverySuggestion):
            return recoverySuggestion
        case .invalidDatabase(let path):
            return "Make sure the path \(path) is valid and the device has available storage space."
        case .invalidOperation(let causedBy):
            return causedBy?.localizedDescription ?? ""
        case .nonUniqueResult:
            return """
            Check that the condition applied to the query actually guarantees uniqueness, such
            as unique indexes, primary keys.
            """
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .configuration(_, _, let underlyingError):
            return underlyingError
        case .invalidDatabase(_, let underlyingError):
            return underlyingError
        case .invalidOperation(let underlyingError):
            return underlyingError
        default:
            return nil
        }
    }
}
