//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum DataStoreResult<Result> {
    case result(_ result: Result)
    case error(_ error: DataStoreError)
}

extension DataStoreResult {
    static func from(error: Error) -> Self {
        let dataStoreError = error as? DataStoreError ?? .invalidOperation(causedBy: error)
        return .error(dataStoreError)
    }
}

public typealias DataStoreCallback<Result> = (DataStoreResult<Result>) -> Void

public func ignoreDataStoreResult<T>(_ result: DataStoreResult<T>) {
    switch result {
    case .error(let error):
        fatalError("Unhandled DataStore error: \(error.errorDescription)")
    case .result(_):
        // TODO log ignored result
        break
    }
}
