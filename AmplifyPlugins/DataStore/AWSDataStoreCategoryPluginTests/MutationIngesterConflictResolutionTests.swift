//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

// swiftlint:disable type_body_length
// TODO: Split these tests into separate suites

/// Tests in this class have a naming convention of `test_<existing>_<candidate>`, which is to say: given that the
/// mutation queue has an existing record of type `<existing>`, assert the behavior when candidate a mutation of
/// type `<candidate>`.
class MutationIngesterConflictResolutionTests: XCTestCase {

    /// Mock used to listen for API calls; this is how we assert that syncEngine is delivering events to the API
    var apiPlugin: MockAPICategoryPlugin!

    /// Used for DB manipulation to mock starting data for tests
    var storageAdapter: SQLiteStorageEngineAdapter!

    /// Populated during setUp, used in each test during `Amplify.configure()`
    var amplifyConfig: AmplifyConfiguration!

    override func setUp() {
        continueAfterFailure = false

        Amplify.reset()
        Amplify.Logging.logLevel = .verbose
        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)

        let apiConfig = APICategoryConfiguration(plugins: [
            "MockAPICategoryPlugin": true
        ])

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStoreCategoryPlugin": true
        ])

        amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: dataStoreConfig)

        apiPlugin = MockAPICategoryPlugin()
        tryOrFail {
            try Amplify.add(plugin: apiPlugin)
        }
    }

    // MARK: - Existing == .create

    /// - Given: An existing MutationEvent of type .create
    /// - When:
    ///    - I submit a .create MutationEvent for the same object
    /// - Then:
    ///    - I receive an error
    ///    - The mutation queue retains the original event
    func test_create_create() throws {
        setUpStorageAdapter()

        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: Date())
        try saveMutationEvent(of: .create, for: post)

        try startAmplifyAndWaitForSync()

        let saveResultReceived = expectation(description: "Save result received")
        Amplify.DataStore.save(post) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNotNil(dataStoreError)
            case .success(let post):
                XCTAssertNil(post)
            }
            saveResultReceived.fulfill()
        }

        wait(for: [saveResultReceived], timeout: 1.0)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self,
                             predicate: MutationEvent.keys.id == mutationEventId(for: post)) { result in
                                switch result {
                                case .failure(let dataStoreError):
                                    XCTAssertNil(dataStoreError)
                                case .success(let mutationEvents):
                                    XCTAssertEqual(mutationEvents.count, 1)
                                    XCTAssertEqual(mutationEvents.first?.json, try? post.toJSON())
                                }
                                mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    /// - Given: An existing MutationEvent of type .create
    /// - When:
    ///    - I submit a .update MutationEvent for the same object
    /// - Then:
    ///    - The update is saved to DataStore
    ///    - The mutation event is updated with the new values
    func test_create_update() throws {
        setUpStorageAdapter()

        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: Date())
        try saveMutationEvent(of: .create, for: post)

        try savePost(post)

        try startAmplifyAndWaitForSync()

        var mutatedPost = post
        mutatedPost.content = "UPDATED CONTENT"
        let saveResultReceived = expectation(description: "Save result received")
        Amplify.DataStore.save(mutatedPost) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success(let post):
                XCTAssertEqual(post.content, mutatedPost.content)
            }
            saveResultReceived.fulfill()
        }

        wait(for: [saveResultReceived], timeout: 1.0)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self,
                             predicate: MutationEvent.keys.id == mutationEventId(for: post)) { result in
                                switch result {
                                case .failure(let dataStoreError):
                                    XCTAssertNil(dataStoreError)
                                case .success(let mutationEvents):
                                    let mutationEvent = mutationEvents.first!
                                    XCTAssertEqual(mutationEvent.json, try? mutatedPost.toJSON())
                                    XCTAssertEqual(mutationEvent.mutationType, GraphQLMutationType.create.rawValue)
                                }
                                mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    /// - Given: An existing MutationEvent of type .create
    /// - When:
    ///    - I submit a .delete MutationEvent for the same object
    /// - Then:
    ///    - The delete is saved to DataStore
    ///    - The mutation event is removed from the mutation queue
    func test_create_delete() throws {
        setUpStorageAdapter()

        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: Date())
        try saveMutationEvent(of: .create, for: post)

        try savePost(post)

        try startAmplifyAndWaitForSync()

        let deleteResultReceived = expectation(description: "Delete result received")
        Amplify.DataStore.delete(post) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success:
                // Void result, do nothing
                break
            }
            deleteResultReceived.fulfill()
        }

        wait(for: [deleteResultReceived], timeout: 1.0)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self,
                             predicate: MutationEvent.keys.id == mutationEventId(for: post)) { result in
                                switch result {
                                case .failure(let dataStoreError):
                                    XCTAssertNil(dataStoreError)
                                case .success(let mutationEvents):
                                    XCTAssertEqual(mutationEvents.count, 0)
                                }
                                mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    // MARK: - Existing == .update

    /// - Given: An existing MutationEvent of type .update
    /// - When:
    ///    - I submit a .create MutationEvent for the same object
    /// - Then:
    ///    - I receive an error
    ///    - The mutation queue retains the original event
    func test_update_create() throws {
        setUpStorageAdapter()

        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: Date())
        try saveMutationEvent(of: .update, for: post)

        try startAmplifyAndWaitForSync()

        let saveResultReceived = expectation(description: "Save result received")
        Amplify.DataStore.save(post) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNotNil(dataStoreError)
            case .success(let post):
                XCTAssertNil(post)
            }
            saveResultReceived.fulfill()
        }

        wait(for: [saveResultReceived], timeout: 1.0)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self,
                             predicate: MutationEvent.keys.id == mutationEventId(for: post)) { result in
                                switch result {
                                case .failure(let dataStoreError):
                                    XCTAssertNil(dataStoreError)
                                case .success(let mutationEvents):
                                    XCTAssertEqual(mutationEvents.count, 1)
                                    XCTAssertEqual(mutationEvents.first?.mutationType,
                                                   GraphQLMutationType.update.rawValue)
                                    XCTAssertEqual(mutationEvents.first?.json, try? post.toJSON())
                                }
                                mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    /// - Given: An existing MutationEvent of type .update
    /// - When:
    ///    - I submit a .update MutationEvent for the same object
    /// - Then:
    ///    - The update is saved to DataStore
    ///    - The mutation event is updated with the new values
    func test_update_update() throws {
        setUpStorageAdapter()

        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: Date())
        try saveMutationEvent(of: .update, for: post)

        try savePost(post)

        try startAmplifyAndWaitForSync()

        var mutatedPost = post
        mutatedPost.content = "UPDATED CONTENT"
        let saveResultReceived = expectation(description: "Save result received")
        Amplify.DataStore.save(mutatedPost) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success(let post):
                XCTAssertEqual(post.content, mutatedPost.content)
            }
            saveResultReceived.fulfill()
        }

        wait(for: [saveResultReceived], timeout: 1.0)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self,
                             predicate: MutationEvent.keys.id == mutationEventId(for: post)) { result in
                                switch result {
                                case .failure(let dataStoreError):
                                    XCTAssertNil(dataStoreError)
                                case .success(let mutationEvents):
                                    let mutationEvent = mutationEvents.first!
                                    XCTAssertEqual(mutationEvent.json, try? mutatedPost.toJSON())
                                    XCTAssertEqual(mutationEvent.mutationType, GraphQLMutationType.update.rawValue)
                                }
                                mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    /// - Given: An existing MutationEvent of type .update
    /// - When:
    ///    - I submit a .update MutationEvent for the same object
    /// - Then:
    ///    - The delete is saved to DataStore
    ///    - The mutation event is updated to a .delete type
    func test_update_delete() throws {
        setUpStorageAdapter()

        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: Date())
        try saveMutationEvent(of: .update, for: post)

        try savePost(post)

        try startAmplifyAndWaitForSync()

        let saveResultReceived = expectation(description: "Delete result received")
        Amplify.DataStore.delete(post) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success:
                // Void result, do nothing
                break
            }
            saveResultReceived.fulfill()
        }

        wait(for: [saveResultReceived], timeout: 1.0)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self,
                             predicate: MutationEvent.keys.id == mutationEventId(for: post)) { result in
                                switch result {
                                case .failure(let dataStoreError):
                                    XCTAssertNil(dataStoreError)
                                case .success(let mutationEvents):
                                    let mutationEvent = mutationEvents.first!
                                    XCTAssertEqual(mutationEvent.mutationType, GraphQLMutationType.delete.rawValue)
                                }
                                mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    // MARK: - Existing == .delete

    /// - Given: An existing MutationEvent of type .delete
    /// - When:
    ///    - I submit a .create MutationEvent for the same object
    /// - Then:
    ///    - I receive an error
    ///    - The mutation queue retains the original event
    func test_delete_create() throws {
        setUpStorageAdapter()

        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: Date())
        try saveMutationEvent(of: .delete, for: post)

        try startAmplifyAndWaitForSync()

        let saveResultReceived = expectation(description: "Save result received")
        Amplify.DataStore.save(post) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNotNil(dataStoreError)
            case .success(let post):
                XCTAssertNil(post)
            }
            saveResultReceived.fulfill()
        }

        wait(for: [saveResultReceived], timeout: 1.0)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self,
                             predicate: MutationEvent.keys.id == mutationEventId(for: post)) { result in
                                switch result {
                                case .failure(let dataStoreError):
                                    XCTAssertNil(dataStoreError)
                                case .success(let mutationEvents):
                                    let mutationEvent = mutationEvents.first!
                                    XCTAssertEqual(mutationEvent.mutationType, GraphQLMutationType.delete.rawValue)
                                }
                                mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    // test_<existing>_<candidate>
    /// - Given: An existing MutationEvent of type .delete
    /// - When:
    ///    - I submit a .update MutationEvent for the same object
    /// - Then:
    ///    - I receive an error
    ///    - The mutation queue retains the original event
    func test_delete_update() throws {
        setUpStorageAdapter()

        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: Date())
        try saveMutationEvent(of: .delete, for: post)

        try savePost(post)

        try startAmplifyAndWaitForSync()

        var mutatedPost = post
        mutatedPost.content = "UPDATED CONTENT"
        let saveResultReceived = expectation(description: "Save result received")
        Amplify.DataStore.save(mutatedPost) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNotNil(dataStoreError)
            case .success(let post):
                XCTAssertNil(post)
            }
            saveResultReceived.fulfill()
        }

        wait(for: [saveResultReceived], timeout: 1.0)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self,
                             predicate: MutationEvent.keys.id == mutationEventId(for: post)) { result in
                                switch result {
                                case .failure(let dataStoreError):
                                    XCTAssertNil(dataStoreError)
                                case .success(let mutationEvents):
                                    let mutationEvent = mutationEvents.first!
                                    XCTAssertEqual(mutationEvent.mutationType, GraphQLMutationType.delete.rawValue)
                                }
                                mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    // MARK: - Empty queue tests

    /// - Given: An empty mutation queue
    /// - When:
    ///    - I perform a .create mutation
    /// - Then:
    ///    - The update is saved to DataStore
    ///    - The mutation event is appended to the queue
    func testCreateMutationAppendedToEmptyQueue() throws {
        setUpStorageAdapter()

        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: Date())

        try startAmplifyAndWaitForSync()

        let saveResultReceived = expectation(description: "Save result received")
        Amplify.DataStore.save(post) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNotNil(dataStoreError)
            case .success(let post):
                XCTAssertNotNil(post)
            }
            saveResultReceived.fulfill()
        }

        wait(for: [saveResultReceived], timeout: 1.0)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self, predicate: nil) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success(let mutationEvents):
                let mutationEvent = mutationEvents.first!
                XCTAssertEqual(mutationEvent.json, try? post.toJSON())
                XCTAssertEqual(mutationEvent.mutationType, GraphQLMutationType.create.rawValue)
            }
            mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    /// - Given: An empty mutation queue
    /// - When:
    ///    - I perform a .update mutation
    /// - Then:
    ///    - The update is saved to DataStore
    ///    - The mutation event is appended to the queue
    func testUpdateMutationAppendedToEmptyQueue() throws {
        setUpStorageAdapter()

        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: Date())

        try savePost(post)

        try startAmplifyAndWaitForSync()

        let saveResultReceived = expectation(description: "Save result received")
        Amplify.DataStore.save(post) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNotNil(dataStoreError)
            case .success(let post):
                XCTAssertNotNil(post)
            }
            saveResultReceived.fulfill()
        }

        wait(for: [saveResultReceived], timeout: 1.0)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self, predicate: nil) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success(let mutationEvents):
                let mutationEvent = mutationEvents.first!
                XCTAssertEqual(mutationEvent.json, try? post.toJSON())
                XCTAssertEqual(mutationEvent.mutationType, GraphQLMutationType.update.rawValue)
            }
            mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    /// - Given: An empty mutation queue
    /// - When:
    ///    - I perform a .delete mutation
    /// - Then:
    ///    - The update is saved to DataStore
    ///    - The mutation event is appended to the queue
    func testDeleteMutationAppendedToEmptyQueue() throws {
        setUpStorageAdapter()

        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: Date())

        try savePost(post)

        try startAmplifyAndWaitForSync()

        let saveResultReceived = expectation(description: "Save result received")
        Amplify.DataStore.delete(post) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNotNil(dataStoreError)
            case .success:
                // Void result, no assertion
                break
            }
            saveResultReceived.fulfill()
        }

        wait(for: [saveResultReceived], timeout: 1.0)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self, predicate: nil) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success(let mutationEvents):
                let mutationEvent = mutationEvents.first!
                XCTAssertEqual(mutationEvent.modelId, post.id)
                XCTAssertEqual(mutationEvent.mutationType, GraphQLMutationType.delete.rawValue)
            }
            mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    // MARK: - In-process queue tests

    /// - Given: A mutation queue with an in-process .create event
    /// - When:
    ///    - I perform a .create mutation
    /// - Then:
    ///    - The update is saved to DataStore
    ///    - The mutation event is appended to the queue, even though it would normally have thrown an error
    func testCreateMutationAppendedToInProcessQueue() throws {
        setUpStorageAdapter()

        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: Date())
        try saveMutationEvent(of: .create, for: post, inProcess: true)

        try startAmplifyAndWaitForSync()

        let saveResultReceived = expectation(description: "Save result received")
        Amplify.DataStore.save(post) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNotNil(dataStoreError)
            case .success(let post):
                XCTAssertNotNil(post)
            }
            saveResultReceived.fulfill()
        }

        wait(for: [saveResultReceived], timeout: 1.0)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self, predicate: nil) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success(let mutationEvents):
                XCTAssertEqual(mutationEvents.count, 2)
                XCTAssertEqual(mutationEvents[0].mutationType, GraphQLMutationType.create.rawValue)
                XCTAssertEqual(mutationEvents[1].mutationType, GraphQLMutationType.create.rawValue)
            }
            mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    /// - Given: A mutation queue with an in-process .create event
    /// - When:
    ///    - I perform a .update mutation
    /// - Then:
    ///    - The update is saved to DataStore
    ///    - The mutation event is appended to the queue, even though it would normally have overwritten the existing
    ///      create
    func testUpdateMutationAppendedToInProcessQueue() throws {
        setUpStorageAdapter()

        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: Date())
        try saveMutationEvent(of: .create, for: post, inProcess: true)

        try savePost(post)

        try startAmplifyAndWaitForSync()

        var mutatedPost = post
        mutatedPost.content = "UPDATED CONTENT"
        let saveResultReceived = expectation(description: "Save result received")
        Amplify.DataStore.save(mutatedPost) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success(let post):
                XCTAssertEqual(post.content, mutatedPost.content)
            }
            saveResultReceived.fulfill()
        }

        wait(for: [saveResultReceived], timeout: 1.0)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self, predicate: nil) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success(let mutationEvents):
                XCTAssertEqual(mutationEvents.count, 2)
                XCTAssertEqual(mutationEvents[0].mutationType, GraphQLMutationType.create.rawValue)
                XCTAssertEqual(mutationEvents[0].json, try? post.toJSON())

                XCTAssertEqual(mutationEvents[1].mutationType, GraphQLMutationType.update.rawValue)
                XCTAssertEqual(mutationEvents[1].json, try? mutatedPost.toJSON())
            }
            mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    /// - Given: A mutation queue with an in-process .create event
    /// - When:
    ///    - I perform a .delete mutation
    /// - Then:
    ///    - The update is saved to DataStore
    ///    - The mutation event is appended to the queue, even though it would normally have thrown an error
    func testDeleteMutationAppendedToInProcessQueue() throws {
        setUpStorageAdapter()

        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: Date())
        try saveMutationEvent(of: .create, for: post, inProcess: true)

        try startAmplifyAndWaitForSync()

        let deleteResultReceived = expectation(description: "Delete result received")
        Amplify.DataStore.delete(post) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNotNil(dataStoreError)
            case .success:
                // Void result
                break
            }
            deleteResultReceived.fulfill()
        }

        wait(for: [deleteResultReceived], timeout: 1.0)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self, predicate: nil) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success(let mutationEvents):
                XCTAssertEqual(mutationEvents.count, 2)
                XCTAssertEqual(mutationEvents[0].mutationType, GraphQLMutationType.create.rawValue)
                XCTAssertEqual(mutationEvents[1].mutationType, GraphQLMutationType.delete.rawValue)
            }
            mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    // MARK: - Helpers

    /// Sets up a StorageAdapter backed by an in-memory SQLite database
    func setUpStorageAdapter() {
        tryOrFail {
            let connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            try storageAdapter.setUp(models: StorageEngine.systemModels + [Post.self, Comment.self])
        }
    }

    func setUpDataStore() {
        tryOrFail {

            let mutationDatabaseAdapter = try AWSMutationDatabaseAdapter(storageAdapter: storageAdapter)
            let awsMutationEventPublisher = AWSMutationEventPublisher(eventSource: mutationDatabaseAdapter)
            let outgoingMutationQueue = NoOpMutationQueue()

            let syncEngine = CloudSyncEngine(storageAdapter: storageAdapter,
                                             outgoingMutationQueue: outgoingMutationQueue,
                                             mutationEventIngester: mutationDatabaseAdapter,
                                             mutationEventPublisher: awsMutationEventPublisher)

            let storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                              syncEngine: syncEngine,
                                              isSyncEnabled: true)

            let publisher = DataStorePublisher()
            let dataStorePlugin = AWSDataStoreCategoryPlugin(modelRegistration: TestModelRegistration(),
                                                             storageEngine: storageEngine,
                                                             dataStorePublisher: publisher)

            try Amplify.add(plugin: dataStorePlugin)
        }
    }

    func startAmplify() {
        tryOrFail {
            try Amplify.configure(amplifyConfig)
        }
    }

    func mutationEventId(for post: Post) -> String {
        "mutation-of-\(post.id)"
    }

    func saveMutationEvent(of mutationType: MutationEvent.MutationType,
                           for post: Post,
                           inProcess: Bool = false) throws {
        let mutationEvent = try MutationEvent(id: mutationEventId(for: post),
                                              modelId: post.id,
                                              modelName: post.modelName,
                                              json: post.toJSON(),
                                              mutationType: mutationType,
                                              createdAt: Date(),
                                              inProcess: inProcess)

        let mutationEventSaved = expectation(description: "Preloaded mutation event saved")
        storageAdapter.save(mutationEvent) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTFail(String(describing: dataStoreError))
            case .success:
                mutationEventSaved.fulfill()
            }
        }
        wait(for: [mutationEventSaved], timeout: 1.0)
    }

    // Several tests require there to be a post in the database prior to starting. This utility supports that.
    func savePost(_ post: Post) throws {
        let postSaved = expectation(description: "Preloaded mutation event saved")
        storageAdapter.save(post) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTFail(String(describing: dataStoreError))
            case .success:
                postSaved.fulfill()
            }
        }
        wait(for: [postSaved], timeout: 1.0)
    }

    func startAmplifyAndWaitForSync() throws {
        setUpDataStore()

        let syncStarted = expectation(description: "Sync started")
        let token = Amplify.Hub.listen(to: .dataStore,
                                       eventName: HubPayload.EventName.DataStore.syncStarted) { _ in
                                        syncStarted.fulfill()
        }

        guard try HubListenerTestUtilities.waitForListener(with: token, timeout: 5.0) else {
            XCTFail("Never registered listener for sync started")
            return
        }

        startAmplify()

        wait(for: [syncStarted], timeout: 5.0)
        Amplify.Hub.removeListener(token)
    }
}
