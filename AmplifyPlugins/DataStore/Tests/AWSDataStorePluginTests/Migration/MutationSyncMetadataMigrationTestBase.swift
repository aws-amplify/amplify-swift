//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin
@testable import AWSPluginsCore

class MutationSyncMetadataMigrationTestBase: XCTestCase {
    var storageAdapter: SQLiteStorageEngineAdapter!
    var modelSchemas: [ModelSchema]!

    override func setUp() {
        super.setUp()
        Amplify.Logging.logLevel = .debug
        do {
            let connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            modelSchemas = [Restaurant.schema, Menu.schema, Dish.schema]
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    func setUpAllModels() throws {
        try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)

        ModelRegistry.register(modelType: Restaurant.self)
        ModelRegistry.register(modelType: Menu.self)
        ModelRegistry.register(modelType: Dish.self)
        do {
            try storageAdapter.setUp(modelSchemas: modelSchemas)
        } catch {
            XCTFail("Failed to setup storage engine")
        }
    }

    // MARK: - Helpers

    func save<M: Model>(_ model: M) {
        if case .failure(let error) = storageAdapter.save(model, modelSchema: model.schema, condition: nil, eagerLoad: true) {
            XCTFail("\(error.errorDescription)")
        }
    }

    func saveMutationSyncMetadata(_ metadata: MutationSyncMetadata) {
        let result = storageAdapter.save(
            metadata,
            modelSchema: metadata.schema,
            condition: nil,
            eagerLoad: true
        )

        if case .failure(let error) = result {
            XCTFail("\(error.errorDescription)")
        }
    }

    func queryMutationSyncMetadata() -> [MutationSyncMetadata]? {
        storageAdapter.query(
            MutationSyncMetadata.self,
            modelSchema: MutationSyncMetadata.schema,
            condition: nil,
            sort: nil,
            paginationInput: nil,
            eagerLoad: true
        )
        .ifFailure { XCTFail("\($0)") }
        .toOptional()

    }

    func queryModelSyncMetadata() -> [ModelSyncMetadata]? {
        storageAdapter.query(
            ModelSyncMetadata.self,
            modelSchema: ModelSyncMetadata.schema,
            condition: nil,
            sort: nil,
            paginationInput: nil,
            eagerLoad: true
        )
        .ifFailure { XCTFail("\($0)") }
        .toOptional()
    }
}
