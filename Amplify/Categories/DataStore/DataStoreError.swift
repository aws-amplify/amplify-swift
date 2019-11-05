//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// MARK: - Enum

public enum DataStoreError: Error {
    case invalidDatabase
    case invalidOperation(causedBy: Error?)
    case nonUniqueResult(model: String)
}

// MARK: - AmplifyError

extension DataStoreError: AmplifyError {

    public var errorDescription: ErrorDescription {
        switch self {
        case .invalidDatabase:
            return ""
        case .invalidOperation(let causedBy):
            return causedBy?.localizedDescription ?? ""
        case .nonUniqueResult(let model):
            return "The result of the queried model of type \(model) return more than one result"
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .invalidDatabase:
            return ""
        case .invalidOperation(let causedBy):
            return causedBy?.localizedDescription ?? ""
        case .nonUniqueResult:
            return """
            Check that the condition applied to the query actually guarantees uniqueness, such
            as unique indexes, primary keys.
            """
        }
    }

}
