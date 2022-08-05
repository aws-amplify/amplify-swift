//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

import Foundation
import SQLite

// swiftlint:disable type_body_length
class SQLiteStorageEngineAdapterJsonTests: XCTestCase {

    var connection: Connection!
    var storageEngine: StorageEngine!
    var storageAdapter: SQLiteStorageEngineAdapter!

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        await Amplify.reset()
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
        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
            return self.storageEngine
        }
        let dataStorePublisher = DataStorePublisher()
        let dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestJsonModelRegistration(),
                                                 storageEngineBehaviorFactory: storageEngineBehaviorFactory,
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
            Amplify.DataStore.start(completion: {_ in})
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
        let createdAt = Temporal.DateTime.now().iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
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
                            XCTAssertEqual(model.jsonValue(for: "createdAt") as? String, createdAt)
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
    ///   - call `query(Post, where: title == post.title)` to check
    ///   if the model was correctly inserted using a predicate
    func testInsertPostAndSelectByTitle() {
        let expectation = self.expectation(
            description: "it should save and select a Post from the database")

        // insert a post
        // insert a post
        let title = "a title"
        let content = "some content"
        let createdAt = Temporal.DateTime.now().iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
        let model = DynamicModel(values: post)
        storageAdapter.save(model, modelSchema: ModelRegistry.modelSchema(from: "Post")!) { saveResult in
            switch saveResult {
            case .success:
                let predicate = QueryPredicateOperation(field: "title", operator: .equals(title))
                self.storageAdapter.query(Post.self, predicate: predicate) { queryResult in
                    switch queryResult {
                    case .success(let posts):
                        XCTAssertEqual(posts.count, 1)
                        if let savedPost = posts.first {
                            XCTAssertEqual(model.id, savedPost.id)
                            XCTAssertEqual(model.jsonValue(for: "title") as? String, title)
                            XCTAssertEqual(model.jsonValue(for: "content") as? String, content)
                            XCTAssertEqual(model.jsonValue(for: "createdAt") as? String, createdAt)
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
        let createdAt = Temporal.DateTime.now().iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
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
                let updatedPost = ["title": .string("title updated"),
                                   "content": .string(content),
                                   "createdAt": .string(createdAt)] as [String: JSONValue]
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
        let createdAt = Temporal.DateTime.now().iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
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

    /// - Given: A Post instance
    /// - When:
    ///    - The `save(post)` is called
    /// - Then:
    ///    - call `update(post, condition)` with `post.title` updated and condition matches `post.content`
    ///    - a successful update for `update(post, condition)`
    ///    - call `query(Post)` to check if the model was correctly updated
    func testInsertPostAndThenUpdateItWithCondition() {
        let expectation = self.expectation(description: "it should insert and update a Post")
        let schema = ModelRegistry.modelSchema(from: "Post")!
        func checkSavedPost(id: String) {
            storageAdapter.query(DynamicModel.self, modelSchema: schema) {
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

        // insert a post
        let title = "a title"
        let content = "some content"
        let createdAt = Temporal.DateTime.now().iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
        let model = DynamicModel(values: post)

        storageAdapter.save(model, modelSchema: schema) { insertResult in
            switch insertResult {
            case .success:
                let updatedPost = ["title": .string("title updated"),
                                   "content": .string(content),
                                   "createdAt": .string(createdAt)] as [String: JSONValue]
                let updatedModel = DynamicModel(id: model.id, values: updatedPost)
                let condition = QueryPredicateOperation(field: "content", operator: .equals(content))
                self.storageAdapter.save(updatedModel, modelSchema: schema, condition: condition) { updateResult in
                    switch updateResult {
                    case .success:
                        checkSavedPost(id: updatedModel.id)
                    case .failure(let error):
                        XCTFail(error.errorDescription)
                    }
                }
            case .failure(let error):
                XCTFail(String(describing: error))
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    /// - Given: A Post instance
    /// - When:
    ///    - The `save(post, condition)` is called, condition is passed in.
    /// - Then:
    ///    - Fails with conditional save failed error when there is no existing model instance
    func testUpdateWithConditionFailsWhenNoExistingModel() {
        let expectation = self.expectation(
            description: "it should fail to update the Post that does not exist")

        // insert a post
        let title = "a title"
        let content = "some content"
        let createdAt = Temporal.DateTime.now().iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
        let model = DynamicModel(values: post)
        let schema = ModelRegistry.modelSchema(from: "Post")!
        let condition = QueryPredicateOperation(field: "content", operator: .equals(content))
        storageAdapter.save(model, modelSchema: schema, condition: condition) { insertResult in
            switch insertResult {
            case .success:
                XCTFail("Update should not be successful")
            case .failure(let error):
                guard case .invalidCondition = error else {
                    XCTFail("Did not match invalid condition error")
                    return
                }

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    /// - Given: A Post instance
    /// - When:
    ///    - The `save(post)` is called
    /// - Then:
    ///    - call `update(post, condition)` with `post.title` updated and condition does not match
    ///    - the update for `update(post, condition)` fails with conditional save failed error
    func testInsertPostAndThenUpdateItWithConditionDoesNotMatchShouldReturnError() {
        let expectation = self.expectation(
            description: "it should insert and then fail to update the Post, given bad condition")

        // insert a post
        let title = "title not updated"
        let content = "some content"
        let createdAt = Temporal.DateTime.now().iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
        let model = DynamicModel(values: post)
        let schema = ModelRegistry.modelSchema(from: "Post")!

        storageAdapter.save(model, modelSchema: schema) { insertResult in
            switch insertResult {
            case .success:
                let updatedPost = ["title": .string("title updated"),
                                   "content": .string(content),
                                   "createdAt": .string(createdAt)] as [String: JSONValue]
                let updatedModel = DynamicModel(id: model.id, values: updatedPost)
                let condition = QueryPredicateOperation(field: "content",
                                                        operator: .equals("content 2 does not match previous content"))
                self.storageAdapter.save(updatedModel,
                                         modelSchema: schema,
                                         condition: condition) { updateResult in
                    switch updateResult {
                    case .success:
                        XCTFail("Update should not be successful")
                    case .failure(let error):
                        guard case .invalidCondition = error else {
                            XCTFail("Did not match invalid conditiion")
                            return
                        }

                        expectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail(String(describing: error))
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    func testInsertSinglePostThenDeleteItByPredicate() {
        let dateTestStart = Temporal.DateTime.now()
        let dateInFuture = dateTestStart + .seconds(10)
        let saveExpectation = expectation(description: "Saved")
        let deleteExpectation = expectation(description: "Deleted")
        let queryExpectation = expectation(description: "Queried")

        // insert a post
        let title = "title1"
        let content = "content1"
        let createdAt = dateInFuture.iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
        let model = DynamicModel(values: post)
        let schema = ModelRegistry.modelSchema(from: "Post")!

        storageAdapter.save(model, modelSchema: schema) { insertResult in
            switch insertResult {
            case .success:
                saveExpectation.fulfill()
                let predicate = QueryPredicateOperation(field: "createdAt",
                                                        operator: .greaterThan(dateTestStart.iso8601String))
                self.storageAdapter.delete(DynamicModel.self,
                                           modelSchema: Post.schema,
                                           filter: predicate) { result in
                    switch result {
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

    func testInsertionOfManyItemsThenDeleteAllByPredicateConstant() {
        let saveExpectation = expectation(description: "Saved 10 items")
        let deleteExpectation = expectation(description: "Deleted 10 items")
        let queryExpectation = expectation(description: "Queried 10 items")

        let titleX = "title"
        let contentX = "content"
        var counter = 0
        let maxCount = 10
        let schema = ModelRegistry.modelSchema(from: "Post")!
        var postsAdded: [String] = []
        while counter < maxCount {
            let title = "\(titleX)\(counter)"
            let content = "\(contentX)\(counter)"
            let createdAt = Temporal.DateTime.now().iso8601String
            let post = ["title": .string(title),
                        "content": .string(content),
                        "createdAt": .string(createdAt)] as [String: JSONValue]
            let model = DynamicModel(values: post)

            storageAdapter.save(model, modelSchema: schema) { insertResult in
                switch insertResult {
                case .success:
                    postsAdded.append(model.id)
                    if counter == maxCount - 1 {
                        saveExpectation.fulfill()
                        self.storageAdapter.delete(DynamicModel.self,
                                                   modelSchema: schema,
                                                   filter: QueryPredicateConstant.all) { result in
                            switch result {
                            case .success:
                                deleteExpectation.fulfill()
                                for postId in postsAdded {
                                    self.checkIfPostIsDeleted(id: postId)
                                }
                                queryExpectation.fulfill()
                            case .failure(let error):
                                XCTFail(error.errorDescription)
                            }
                        }
                    }
                case .failure(let error):
                    XCTFail(String(describing: error))
                }
            }
            counter += 1
        }
        wait(for: [saveExpectation, deleteExpectation, queryExpectation], timeout: 5)
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
