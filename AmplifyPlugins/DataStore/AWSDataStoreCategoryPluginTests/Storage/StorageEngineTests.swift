//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class StorageEngineTests: XCTestCase {

    let defaultTimeout = 0.3
    var connection: Connection!
    var storageEngine: StorageEngine!
    var storageAdapter: SQLiteStorageEngineAdapter!
    var syncEngine: MockRemoteSyncEngine!

    override func setUp() {
        super.setUp()
        Amplify.Logging.logLevel = .warn

        let validAPIPluginKey = "MockAPICategoryPlugin"
        let validAuthPluginKey = "MockAuthCategoryPlugin"
        do {
            connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)

            syncEngine = MockRemoteSyncEngine()
            storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                          dataStoreConfiguration: .default,
                                          syncEngine: syncEngine,
                                          validAPIPluginKey: validAPIPluginKey,
                                          validAuthPluginKey: validAuthPluginKey)
            ModelRegistry.register(modelType: Post.self)
            ModelRegistry.register(modelType: Comment.self)
            do {
            try storageEngine.setUp(modelSchemas: [Post.schema])
            try storageEngine.setUp(modelSchemas: [Comment.schema])

            } catch {
                XCTFail("Failed to setup storage engine")
            }
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    func testDeleteParentEmitsMutationEventsForParentAndChild() {
        let post = Post(title: "post1", content: "content1", createdAt: .now())
        guard case .success(let savedPost1) = saveModelSynchronous(model: post) else {
            XCTFail("Failed to save")
            return
        }

        let comment1 = Comment(content: "comment1ForPost1", createdAt: .now() + .weeks(1), post: savedPost1)
        let comment2 = Comment(content: "comment2ForPost1", createdAt: .now() + .days(1), post: savedPost1)
        guard case .success = saveModelSynchronous(model: comment1),
            case .success = saveModelSynchronous(model: comment2) else {
                XCTFail("Failed to save either comment")
                return
        }

        guard case .success =
            querySingleModelSynchronous(modelType: Post.self, predicate: Post.keys.id == savedPost1.id) else {
                XCTFail("Failed to query for single post")
                return
        }

        guard case .success(let comments) =
            queryModelSynchronous(modelType: Comment.self, predicate: Comment.keys.post == savedPost1.id) else {
                XCTFail("Failed to query comment")
                return
        }
        XCTAssertEqual(comments.count, 2)

        let recievedMutationEvent = expectation(description: "Mutation Events submitted to sync engine")
        recievedMutationEvent.expectedFulfillmentCount = 3
        syncEngine.setCallbackOnSubmit(callback: { _ in
            recievedMutationEvent.fulfill()
        })
        guard case .success = deleteModelSynchronousOrFailOtherwise(modelType: Post.self, withId: savedPost1.id) else {
            XCTFail("Failed to delete post")
            return
        }

        wait(for: [recievedMutationEvent], timeout: defaultTimeout)
    }

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

    func deleteModelSynchronousOrFailOtherwise<M: Model>(modelType: M.Type, withId id: String) -> DataStoreResult<M> {
        let result = deleteModelSynchronous(modelType: modelType, withId: id)
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

    func deleteModelSynchronous<M: Model>(modelType: M.Type, withId id: String) -> DataStoreResult<M?> {
        let deleteFinished = expectation(description: "Delete Finished")
        var result: DataStoreResult<M?>?

        storageEngine.delete(modelType, modelSchema: modelType.schema, withId: id, completion: { dResult in
            result = dResult
            deleteFinished.fulfill()
        })

        wait(for: [deleteFinished], timeout: 1)
        guard let deleteResult = result else {
            return .failure(causedBy: "Delete operation timed out")
        }
        return deleteResult
    }
}
