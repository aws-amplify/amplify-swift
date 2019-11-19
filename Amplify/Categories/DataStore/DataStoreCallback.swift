//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Enum that holds the results of a `DataStore` operation.
/// - See: [DataStoreCallback](#DataStoreCallback)
public enum DataStoreResult<Result> {
    case result(_ result: Result)
    case error(_ error: DataStoreError)
}

extension DataStoreResult {

    /// Creates a `DataStoreResult` based on a error raised during `DataStore` operations. In case
    /// the error is not already a `DataStoreError`, it gets wrapped with `.invalidOperation`.
    ///
    /// - Parameter error: the root cause of the failure
    /// - Returns: a `DataStoreResult.error`
    public static func failure(causedBy error: Error) -> Self {
        let dataStoreError = error as? DataStoreError ?? .invalidOperation(causedBy: error)
        return .error(dataStoreError)
    }
}

/// Function type of every `DataStore` asynchronous API.
public typealias DataStoreCallback<Result> = (DataStoreResult<Result>) -> Void

/// Utility callback that can be used to allow `DataStore` related APIs to ignore the result.
/// It is analogous to `@discardableResult` but for asynchronous operations.
///
/// **Implementation Details:** on successful result it emits a warning, so the developer knows
/// there are discarded results. On error it calls `fatalError`.
///
/// - Warning: This should be avoided in production environments. It is a good utility
/// for fast prototyping but consider handling all the results in a production app.
// TODO: This shouldn't be a top-level method
public func ignoreDataStoreResult<T>(_ result: DataStoreResult<T>) {
    switch result {
    case .error(let error):
        fatalError("Unhandled DataStore error: \(error.errorDescription)")
    case .result:
        // TODO log ignored result
        break
    }
}
