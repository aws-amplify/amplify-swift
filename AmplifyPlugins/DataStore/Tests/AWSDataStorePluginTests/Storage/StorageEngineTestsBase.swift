//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class StorageEngineTestsBase: XCTestCase {
    let defaultTimeout = 0.3
    var connection: Connection!
    var storageEngine: StorageEngine!
    var storageAdapter: SQLiteStorageEngineAdapter!
    var syncEngine: MockRemoteSyncEngine!

    /**
     * Below are synchronous conveinence methods.  Please do not add any calls to XCTFail()
     * in these conveinence methods.  Failures should be handled in the body of the unit test.
     */
    func saveModelSynchronous<M: Model>(model: M) -> DataStoreResult<M> {
        let saveFinished = expectation(description: "Save finished")
        var result: DataStoreResult<M>?

        storageEngine.save(model) { sResult in
            result = sResult
            saveFinished.fulfill()
        }
        wait(for: [saveFinished], timeout: defaultTimeout)
        guard let saveResult = result else {
            return .failure(causedBy: "Save operation timed out")
        }
        return saveResult
    }
    
    func saveModelSynchronous<M: Model>(model: M) async -> DataStoreResult<M> {
        let saveFinished = expectation(description: "Save finished")
        var result: DataStoreResult<M>?

        storageEngine.save(model) { sResult in
            result = sResult
            saveFinished.fulfill()
        }
        await waitForExpectations(timeout: defaultTimeout)
        guard let saveResult = result else {
            return .failure(causedBy: "Save operation timed out")
        }
        return saveResult
    }

    func saveAsync<M: Model>(_ model: M) async throws -> M {
        try await withCheckedThrowingContinuation { continuation in
            storageEngine.save(model) { sResult in
                continuation.resume(with: sResult)
            }
        }
    }
    
    func querySingleModelSynchronous<M: Model>(modelType: M.Type, predicate: QueryPredicate) -> DataStoreResult<M> {
        let result = queryModelSynchronous(modelType: modelType, predicate: predicate)

        switch result {
        case .success(let models):
            if models.isEmpty {
                return .failure(causedBy: "Found no models, of type \(modelType.modelName)")
            } else if models.count > 1 {
                return .failure(causedBy: "Found more than one model of type \(modelType.modelName)")
            } else {
                return .success(models.first!)
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    func queryModelSynchronous<M: Model>(modelType: M.Type, predicate: QueryPredicate) -> DataStoreResult<[M]> {
        let queryFinished = expectation(description: "Query Finished")
        var result: DataStoreResult<[M]>?

        storageEngine.query(modelType, predicate: predicate) { qResult in
            result = qResult
            queryFinished.fulfill()
        }

        wait(for: [queryFinished], timeout: defaultTimeout)
        guard let queryResult = result else {
            return .failure(causedBy: "Query operation timed out")
        }
        return queryResult
    }
    
    func queryModelSynchronous<M: Model>(modelType: M.Type, predicate: QueryPredicate) async -> DataStoreResult<[M]> {
        let queryFinished = expectation(description: "Query Finished")
        var result: DataStoreResult<[M]>?

        storageEngine.query(modelType, predicate: predicate) { qResult in
            result = qResult
            queryFinished.fulfill()
        }

        await waitForExpectations(timeout: defaultTimeout)
        guard let queryResult = result else {
            return .failure(causedBy: "Query operation timed out")
        }
        return queryResult
    }
    
    func queryAsync<M: Model>(_ modelType: M.Type,
                              byIdentifier identifier: String,
                              eagerLoad: Bool = true) async throws -> M? {
        let predicate: QueryPredicate = field("id").eq(identifier)
        return try await queryAsync(modelType, predicate: predicate, eagerLoad: eagerLoad).first
    }
    
    func queryAsync<M: Model>(_ modelType: M.Type, predicate: QueryPredicate? = nil, eagerLoad: Bool = true) async throws -> [M] {
        try await withCheckedThrowingContinuation { continuation in
            storageEngine.query(modelType, predicate: predicate, eagerLoad: eagerLoad) { qResult in
                continuation.resume(with: qResult)
            }
        }
    }
    
    func queryStorageAdapter<M: Model>(_ modelType: M.Type,
                                       byIdentifier identifier: String,
                                       eagerLoad: Bool = true) async throws -> M? {
        let predicate: QueryPredicate = field("id").eq(identifier)
        return try await withCheckedThrowingContinuation { continuation in
            storageAdapter.query(modelType, predicate: predicate) { result in
                continuation.resume(with: result)
            }
        }.first
    }

    func deleteModelSynchronousOrFailOtherwise<M: Model>(modelType: M.Type,
                                                         withId id: String,
                                                         where predicate: QueryPredicate? = nil,
                                                         timeout: TimeInterval = 1) -> DataStoreResult<M> {
        let result = deleteModelSynchronous(modelType: modelType,
                                            withId: id,
                                            where: predicate,
                                            timeout: timeout)
        switch result {
        case .success(let model):
            if let model = model {
                return .success(model)
            } else {
                return .failure(causedBy: "")
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    func deleteModelSynchronous<M: Model>(modelType: M.Type,
                                          withId id: String,
                                          where predicate: QueryPredicate? = nil,
                                          timeout: TimeInterval = 10) -> DataStoreResult<M?> {
        let deleteFinished = expectation(description: "Delete Finished")
        var result: DataStoreResult<M?>?

        storageEngine.delete(modelType,
                             modelSchema: modelType.schema,
                             withId: id,
                             condition: predicate,
                             completion: { dResult in
            result = dResult
            deleteFinished.fulfill()
        })

        wait(for: [deleteFinished], timeout: timeout)
        guard let deleteResult = result else {
            return .failure(causedBy: "Delete operation timed out")
        }
        return deleteResult
    }
    
    func deleteAsync<M: Model>(modelType: M.Type,
                               withId id: String,
                               where predicate: QueryPredicate? = nil) async throws -> M? {
        try await withCheckedThrowingContinuation { continuation in
            storageEngine.delete(modelType,
                                 modelSchema: modelType.schema,
                                 withId: id,
                                 condition: predicate) { dResult in
                continuation.resume(with: dResult)
            }
        }
    }
}
