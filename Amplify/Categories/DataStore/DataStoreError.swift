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
}

// MARK: - AmplifyError

extension DataStoreError: AmplifyError {

    public var errorDescription: ErrorDescription {
        switch self {
        case .invalidDatabase:
            return ""
        case .invalidOperation(let causedBy):
            return causedBy?.localizedDescription ?? ""
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .invalidDatabase:
            return ""
        case .invalidOperation(let causedBy):
            return causedBy?.localizedDescription ?? ""
        }
    }

}
