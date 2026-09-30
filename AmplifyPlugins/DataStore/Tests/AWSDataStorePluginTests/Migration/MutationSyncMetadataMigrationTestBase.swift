//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin
@testable import AWSPluginsCore

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class MutationSyncMetadataMigrationTestBase: XCTestCase, @unchecked Sendable {
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

    func save(_ model: some Model) {
        let saveSuccess = expectation(description: "Save successful")
        storageAdapter.save(model) { result in
            switch result {
            case .success: saveSuccess.fulfill()
            case .failure(let error): XCTFail("\(error.errorDescription)")
            }
        }
        wait(for: [saveSuccess], timeout: 1)
    }

    func saveMutationSyncMetadata(_ metadata: MutationSyncMetadata) {
        let saveMetadataSuccess = expectation(description: "Save metadata successful")
        storageAdapter.save(metadata) { result in
            switch result {
            case .success: saveMetadataSuccess.fulfill()
            case .failure(let error): XCTFail("\(error.errorDescription)")
            }
        }
        wait(for: [saveMetadataSuccess], timeout: 1)
    }

    func queryMutationSyncMetadata() -> [MutationSyncMetadata]? {
        let firstQueryModelSyncMetadata = expectation(description: "query successful")
        // Assigned from a `@Sendable` completion, so it cannot be a captured `var`.
        let result = AtomicValue<[MutationSyncMetadata]?>(initialValue: nil)
        storageAdapter.query(MutationSyncMetadata.self) {
            switch $0 {
            case .success(let mutationSyncMetadatas):
                result.set(mutationSyncMetadatas)
                firstQueryModelSyncMetadata.fulfill()
            case .failure(let error): XCTFail("\(error.errorDescription)")
            }
        }
        wait(for: [firstQueryModelSyncMetadata], timeout: 1)
        return result.get()
    }

    func queryModelSyncMetadata() -> [ModelSyncMetadata]? {
        let queryModelSyncMetadata = expectation(description: "query model sync metadata successful")
        // Assigned from a `@Sendable` completion, so it cannot be a captured `var`.
        let result = AtomicValue<[ModelSyncMetadata]?>(initialValue: nil)
        storageAdapter.query(ModelSyncMetadata.self) {
            switch $0 {
            case .success(let modelSyncMetadatas):
                result.set(modelSyncMetadatas)
                queryModelSyncMetadata.fulfill()
            case .failure(let error): XCTFail("\(error.errorDescription)")
            }
        }
        wait(for: [queryModelSyncMetadata], timeout: 1)
        return result.get()
    }
}
