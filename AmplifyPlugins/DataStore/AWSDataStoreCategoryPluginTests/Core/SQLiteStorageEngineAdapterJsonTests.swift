//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

import Foundation
import SQLite

class SQLiteStorageEngineAdapterJsonTests: XCTestCase {

    var connection: Connection!
    var storageEngine: StorageEngine!
    var storageAdapter: SQLiteStorageEngineAdapter!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        sleep(2)
        Amplify.reset()
        Amplify.Logging.logLevel = .warn

        let validAPIPluginKey = "MockAPICategoryPlugin"
        let validAuthPluginKey = "MockAuthCategoryPlugin"
        do {
            connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)

            let syncEngine = try RemoteSyncEngine(storageAdapter: storageAdapter,
                                                  dataStoreConfiguration: .default)
            storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                          dataStoreConfiguration: .default,
                                          syncEngine: syncEngine,
                                          validAPIPluginKey: validAPIPluginKey,
                                          validAuthPluginKey: validAuthPluginKey)
        } catch {
            XCTFail(String(describing: error))
            return
        }

        let dataStorePublisher = DataStorePublisher()
        let dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestJsonModelRegistration(),
                                                 storageEngine: storageEngine,
                                                 dataStorePublisher: dataStorePublisher,
                                                 validAPIPluginKey: validAPIPluginKey,
                                                 validAuthPluginKey: validAuthPluginKey)

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStorePlugin": true
        ])
        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        do {

            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post)` is called
    /// - Then:
    ///   - call `query(Post)` to check if the model was correctly inserted
    func testInsertPost() {
        let expectation = self.expectation(
            description: "it should save and select a Post from the database")

        // insert a post
        let title = "a title"
        let content = "some content"



        let post = ["title": .string(title),
                    "content": .string(content)] as [String: JSONValue]
        let model = DynamicModel(values: post)



        storageAdapter.save(model, modelSchema: ModelRegistry.modelSchema(from: "Post")!) { saveResult in
            switch saveResult {
            case .success:
                self.storageAdapter.query(
                    DynamicModel.self,
                    modelSchema: ModelRegistry.modelSchema(from: "Post")!) { queryResult in
                        switch queryResult {
                        case .success(let posts):
                            XCTAssert(posts.count == 1)
                            if let savedPost = posts.first {
                                XCTAssertEqual(model.id, savedPost.id)
                                XCTAssertEqual(model.jsonValue(for: "title") as? String, title)
                                XCTAssertEqual(model.jsonValue(for: "content") as? String, content)
                            }
                            expectation.fulfill()
                        case .failure(let error):
                            XCTFail(String(describing: error))
                            expectation.fulfill()
                        }
                }
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 5)
    }

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post)` is called
    /// - Then:
    ///   - call `save(post)` again with an updated title
    ///   - check if the `query(Post)` returns only 1 post
    ///   - the post has the updated title
    func testInsertPostAndThenUpdateIt() {
        let expectation = self.expectation(
            description: "it should insert and update a Post")

        // insert a post
        let title = "a title"
        let content = "some content"
        let post = ["title": .string(title),
                    "content": .string(content)] as [String: JSONValue]
        let model = DynamicModel(values: post)

        func checkSavedPost(id: String) {
            storageAdapter.query(DynamicModel.self, modelSchema: ModelRegistry.modelSchema(from: "Post")!) {
                switch $0 {
                case .success(let posts):
                    XCTAssertEqual(posts.count, 1)
                    if let post = posts.first {
                        XCTAssertEqual(post.id, id)
                        XCTAssertEqual(post.jsonValue(for: "title") as? String, "title updated")
                    }
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail(String(describing: error))
                    expectation.fulfill()
                }
            }
        }

        storageAdapter.save(model, modelSchema: ModelRegistry.modelSchema(from: "Post")!) { insertResult in
            switch insertResult {
            case .success:
                let updatedPost = ["title": .string("title updated"), "content": .string(content)] as [String: JSONValue]
                let model = DynamicModel(id: model.id, values: updatedPost)
                self.storageAdapter.save(model, modelSchema: ModelRegistry.modelSchema(from: "Post")!) { updateResult in
                    switch updateResult {
                    case .success:
                        checkSavedPost(id: model.id)
                    case .failure(let error):
                        XCTFail(error.errorDescription)
                    }
                }
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post)` is called
    /// - Then:
    ///   - call `delete(Post, id)` and check if `query(Post)` is empty
    ///   - check if `storageAdapter.exists(Post, id)` returns `false`
    func testInsertPostAndThenDeleteIt() {
        let saveExpectation = expectation(description: "Saved")
        let deleteExpectation = expectation(description: "Deleted")
        let queryExpectation = expectation(description: "Queried")

        // insert a post
        let title = "a title"
        let content = "some content"
        let post = ["title": .string(title),
                    "content": .string(content)] as [String: JSONValue]
        let model = DynamicModel(values: post)
        let schema = ModelRegistry.modelSchema(from: "Post")!
        storageAdapter.save(model, modelSchema: schema) { insertResult in
            switch insertResult {
            case .success:
                saveExpectation.fulfill()
                self.storageAdapter.delete(DynamicModel.self, modelSchema: schema, withId: model.id) {
                    switch $0 {
                    case .success:
                        deleteExpectation.fulfill()
                        self.checkIfPostIsDeleted(id: model.id)
                        queryExpectation.fulfill()
                    case .failure(let error):
                        XCTFail(error.errorDescription)
                    }
                }
            case .failure(let error):
                XCTFail(String(describing: error))
            }
        }

        wait(for: [saveExpectation, deleteExpectation, queryExpectation], timeout: 2)
    }

    func checkIfPostIsDeleted(id: String) {
        do {
            let exists = try storageAdapter.exists(ModelRegistry.modelSchema(from: "Post")!, withId: id)
            XCTAssertFalse(exists, "ID \(id) should not exist")
        } catch {
            XCTFail(String(describing: error))
        }
    }
}
