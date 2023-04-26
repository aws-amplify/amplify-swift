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

    
    func saveModel<M: Model>(model: M) async -> DataStoreResult<M> {
        await storageEngine.save(model, modelSchema: model.schema, condition: nil, eagerLoad: true).map { $0.0 }
    }

    @discardableResult
    func saveAsync<M: Model>(_ model: M, eagerLoad: Bool = true) async throws -> M {
        let result = await storageEngine.save(model, modelSchema: model.schema, condition: nil, eagerLoad: eagerLoad).map { $0.0 }
        return try result.get()
    }
    
    func querySingleModel<M: Model>(modelType: M.Type, predicate: QueryPredicate) -> DataStoreResult<M> {
        let result = queryModel(modelType: modelType, predicate: predicate)

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

    func queryModel<M: Model>(modelType: M.Type, predicate: QueryPredicate) -> DataStoreResult<[M]> {
        storageEngine.query(modelType, modelSchema: modelType.schema, condition: predicate)
    }
        
    func queryModel<M: Model>(_ modelType: M.Type,
                              byIdentifier identifier: String,
                              eagerLoad: Bool = true) async throws -> M? {
        let predicate: QueryPredicate = field("id").eq(identifier)
        return try await queryModel(modelType, predicate: predicate, eagerLoad: eagerLoad).first
    }
    
    func queryModel<M: Model>(_ modelType: M.Type, predicate: QueryPredicate? = nil, eagerLoad: Bool = true) async throws -> [M] {
        let result = storageEngine.query(modelType, modelSchema: modelType.schema, condition: predicate, eagerLoad: eagerLoad)
        return try result.get()
    }
    
    func queryStorageAdapter<M: Model>(_ modelType: M.Type,
                                       byIdentifier identifier: String,
                                       eagerLoad: Bool = true) async throws -> M? {

        let predicate: QueryPredicate = field("id").eq(identifier)
        return try storageAdapter.query(
            modelType,
            modelSchema: modelType.schema,
            condition: predicate,
            sort: nil,
            paginationInput: nil,
            eagerLoad: eagerLoad
        ).map { $0.first }.get()
    }

    func deleteModelOrFailOtherwise<M: Model>(
        modelType: M.Type,
        withId id: String,
        where predicate: QueryPredicate? = nil,
        timeout: TimeInterval = 1
    ) async -> DataStoreResult<M> {
        let result = await deleteModel(
            modelType: modelType,
            withId: id,
            where: predicate
        )

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

    func deleteModel<M: Model>(
        modelType: M.Type,
        withId id: String,
        where predicate: QueryPredicate? = nil
    ) async -> Swift.Result<M?, DataStoreError> {
        await storageEngine.delete(
            modelType,
            modelSchema: modelType.schema,
            withIdentifier: DefaultModelIdentifier<M>.makeDefault(id: id),
            condition: predicate
        )
    }
}
