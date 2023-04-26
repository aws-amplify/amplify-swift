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
            try await Amplify.DataStore.start()
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
        // insert a post
        let title = "a title"
        let content = "some content"
        let createdAt = Temporal.DateTime.now().iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
        let model = DynamicModel(values: post)

        let result = storageAdapter.save(
            model,
            modelSchema: ModelRegistry.modelSchema(from: "Post")!,
            condition: nil,
            eagerLoad: true
        ).flatMap { _ in
            self.storageAdapter.query(
                DynamicModel.self,
                modelSchema: ModelRegistry.modelSchema(from: "Post")!,
                condition: nil,
                sort: nil,
                paginationInput: nil,
                eagerLoad: true
            )
        }.ifSuccess { posts in
            XCTAssert(posts.count == 1)
            if let savedPost = posts.first {
                XCTAssertEqual(model.id, savedPost.id)
                XCTAssertEqual(model.jsonValue(for: "title") as? String, title)
                XCTAssertEqual(model.jsonValue(for: "content") as? String, content)
                XCTAssertEqual(model.jsonValue(for: "createdAt") as? String, createdAt)
            }
        }

        if case let .failure(error) = result {
            XCTFail(String(describing: error))
        }
    }

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post)` is called
    /// - Then:
    ///   - call `query(Post, where: title == post.title)` to check
    ///   if the model was correctly inserted using a predicate
    func testInsertPostAndSelectByTitle() {
        // insert a post
        let title = "a title"
        let content = "some content"
        let createdAt = Temporal.DateTime.now().iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
        let model = DynamicModel(values: post)
        storageAdapter.save(
            model,
            modelSchema: ModelRegistry.modelSchema(from: "Post")!,
            condition: nil,
            eagerLoad: true
        ).flatMap { _ in
            let predicate = QueryPredicateOperation(field: "title", operator: .equals(title))
            return self.storageAdapter.query(
                Post.self,
                modelSchema: Post.schema,
                condition: predicate,
                sort: nil,
                paginationInput: nil,
                eagerLoad: true
            )
        }.ifSuccess { posts in
            XCTAssertEqual(posts.count, 1)
            if let savedPost = posts.first {
                XCTAssertEqual(model.id, savedPost.id)
                XCTAssertEqual(model.jsonValue(for: "title") as? String, title)
                XCTAssertEqual(model.jsonValue(for: "content") as? String, content)
                XCTAssertEqual(model.jsonValue(for: "createdAt") as? String, createdAt)
            }
        }.ifFailure { error in
            XCTFail(String(describing: error))
        }
    }

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post)` is called
    /// - Then:
    ///   - call `save(post)` again with an updated title
    ///   - check if the `query(Post)` returns only 1 post
    ///   - the post has the updated title
    func testInsertPostAndThenUpdateIt() {
        // insert a post
        let title = "a title"
        let content = "some content"
        let createdAt = Temporal.DateTime.now().iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
        let model = DynamicModel(values: post)

        storageAdapter.save(
            model,
            modelSchema: ModelRegistry.modelSchema(from: "Post")!,
            condition: nil,
            eagerLoad: true
        ).flatMap { _ in
            let updatedPost = ["title": .string("title updated"),
                               "content": .string(content),
                               "createdAt": .string(createdAt)] as [String: JSONValue]
            let updating = DynamicModel(id: model.id, values: updatedPost)
            return storageAdapter.save(
                updating,
                modelSchema: ModelRegistry.modelSchema(from: "Post")!,
                condition: nil,
                eagerLoad: true
            )
        }.flatMap { _ in
            return storageAdapter.query(
                DynamicModel.self,
                modelSchema: Post.schema,
                condition: nil,
                sort: nil,
                paginationInput: nil,
                eagerLoad: true
            )
        }.ifSuccess { posts in
            XCTAssertEqual(posts.count, 1)
            if let post = posts.first {
                XCTAssertEqual(post.id, model.id)
                XCTAssertEqual(post.jsonValue(for: "title") as? String, "title updated")
            }
        }.ifFailure { error in
            XCTFail(String(describing: error))
        }

    }

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post)` is called
    /// - Then:
    ///   - call `delete(Post, id)` and check if `query(Post)` is empty
    ///   - check if `storageAdapter.exists(Post, id)` returns `false`
    func testInsertPostAndThenDeleteIt() {
        // insert a post
        let title = "a title"
        let content = "some content"
        let createdAt = Temporal.DateTime.now().iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
        let model = DynamicModel(values: post)
        let schema = ModelRegistry.modelSchema(from: "Post")!

        storageAdapter.save(model, modelSchema: schema, condition: nil, eagerLoad: true)
            .flatMap { _ in
                storageAdapter.delete(modelSchema: schema, withIdentifier: model.identifier(schema: schema), condition: nil)
            }.ifSuccess{ _ in
                checkIfPostIsDeleted(id: model.id)
            }.ifFailure { error in
                XCTFail(error.errorDescription)
            }
    }

    /// - Given: A Post instance
    /// - When:
    ///    - The `save(post)` is called
    /// - Then:
    ///    - call `update(post, condition)` with `post.title` updated and condition matches `post.content`
    ///    - a successful update for `update(post, condition)`
    ///    - call `query(Post)` to check if the model was correctly updated
    func testInsertPostAndThenUpdateItWithCondition() {
        let schema = ModelRegistry.modelSchema(from: "Post")!

        // insert a post
        let title = "a title"
        let content = "some content"
        let createdAt = Temporal.DateTime.now().iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
        let model = DynamicModel(values: post)

        storageAdapter.save(model, modelSchema: schema, condition: nil, eagerLoad: true)
            .flatMap({ _ in
                let updatedPost = ["title": .string("title updated"),
                                   "content": .string(content),
                                   "createdAt": .string(createdAt)] as [String: JSONValue]
                let updatedModel = DynamicModel(id: model.id, values: updatedPost)
                let condition = QueryPredicateOperation(field: "content", operator: .equals(content))
                return self.storageAdapter.save(updatedModel, modelSchema: schema, condition: condition, eagerLoad: true)
            })
            .flatMap({ _ in
                storageAdapter.query(
                    DynamicModel.self,
                    modelSchema: schema,
                    condition: nil,
                    sort: nil,
                    paginationInput: nil,
                    eagerLoad: true
                )
            })
            .ifSuccess({ posts in
                XCTAssertEqual(posts.count, 1)
                if let post = posts.first {
                    XCTAssertEqual(post.id, model.id)
                    XCTAssertEqual(post.jsonValue(for: "title") as? String, "title updated")
                }
            })
            .ifFailure({ error in
                XCTFail(error.errorDescription)
            })
    }

    /// - Given: A Post instance
    /// - When:
    ///    - The `save(post, condition)` is called, condition is passed in.
    /// - Then:
    ///    - Fails with conditional save failed error when there is no existing model instance
    func testUpdateWithConditionFailsWhenNoExistingModel() {
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
        storageAdapter.save(model, modelSchema: schema, condition: condition, eagerLoad: true)
            .ifSuccess({ _ in
                XCTFail("Update should not be successful")
            })
            .ifFailure({ error in
                guard case .invalidCondition = error else {
                    XCTFail("Did not match invalid condition error")
                    return
                }
            })
    }

    /// - Given: A Post instance
    /// - When:
    ///    - The `save(post)` is called
    /// - Then:
    ///    - call `update(post, condition)` with `post.title` updated and condition does not match
    ///    - the update for `update(post, condition)` fails with conditional save failed error
    func testInsertPostAndThenUpdateItWithConditionDoesNotMatchShouldReturnError() {
        // insert a post
        let title = "title not updated"
        let content = "some content"
        let createdAt = Temporal.DateTime.now().iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
        let model = DynamicModel(values: post)
        let schema = ModelRegistry.modelSchema(from: "Post")!

        storageAdapter.save(model, modelSchema: schema, condition: nil, eagerLoad: true)
            .ifFailure({ error in
                XCTFail(String(describing: error))
            })
            .flatMap({ _ in
                let updatedPost = ["title": .string("title updated"),
                                   "content": .string(content),
                                   "createdAt": .string(createdAt)] as [String: JSONValue]
                let updatedModel = DynamicModel(id: model.id, values: updatedPost)
                let condition = QueryPredicateOperation(
                    field: "content",
                    operator: .equals("content 2 does not match previous content")
                )

                return storageAdapter.save(
                    updatedModel,
                    modelSchema: schema,
                    condition: condition,
                    eagerLoad: true
                )
            }).ifSuccess({ _ in
                XCTFail("Update should not be successful")
            }).ifFailure({ error in
                guard case .invalidCondition = error else {
                    XCTFail("Did not match invalid conditiion")
                    return
                }
            })

    }

    func testInsertSinglePostThenDeleteItByPredicate() {
        let dateTestStart = Temporal.DateTime.now()
        let dateInFuture = dateTestStart + .seconds(10)

        // insert a post
        let title = "title1"
        let content = "content1"
        let createdAt = dateInFuture.iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
        let model = DynamicModel(values: post)
        let schema = ModelRegistry.modelSchema(from: "Post")!

        storageAdapter.save(model, modelSchema: schema, condition: nil, eagerLoad: true)
            .flatMap({ _ in
                let predicate = QueryPredicateOperation(
                    field: "createdAt",
                    operator: .greaterThan(dateTestStart.iso8601String)
                )
                return storageAdapter.delete(
                    modelSchema: Post.schema,
                    condition: predicate
                )
            }).ifSuccess({ _ in
                self.checkIfPostIsDeleted(id: model.id)
            }).ifFailure({ error in
                XCTFail(error.errorDescription)
            })
    }

    func testInsertionOfManyItemsThenDeleteAllByPredicateConstant() {
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

            storageAdapter.save(model, modelSchema: schema, condition: nil, eagerLoad: true)
                .ifSuccess({ _ in
                    postsAdded.append(model.id)
                })
                .ifFailure({ error in
                    XCTFail(String(describing: error))
                })
            counter += 1
        }

        let result = storageAdapter.delete(
            modelSchema: schema,
            condition: QueryPredicateConstant.all
        )

        switch result {
        case .success:
            for postId in postsAdded {
                self.checkIfPostIsDeleted(id: postId)
            }
        case .failure(let error):
            XCTFail(error.errorDescription)
        }
    }

    func checkIfPostIsDeleted(id: String) {
        let schema = ModelRegistry.modelSchema(from: "Post")!

        storageAdapter.exists(
            schema,
            withIdentifier: DefaultModelIdentifier<Post>.makeDefault(id: id),
            predicate: nil
        ).ifFailure { error in
            XCTFail(String(describing: error))
        }.ifSuccess { exists in
            XCTAssertFalse(exists, "ID \(id) should not exist")
        }
    }
}
