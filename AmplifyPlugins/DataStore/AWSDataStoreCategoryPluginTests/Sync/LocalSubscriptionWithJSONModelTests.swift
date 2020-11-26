//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite

import Combine
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

/// Tests behavior of local DataStore subscriptions (as opposed to remote API subscription behaviors)
/// using serialized JSON models
class LocalSubscriptionWithJSONModelTests: XCTestCase {
    var dataStorePlugin: AWSDataStorePlugin!

    override func setUp() {
        super.setUp()

        Amplify.reset()
        Amplify.Logging.logLevel = .warn

        let storageAdapter: SQLiteStorageEngineAdapter
        let storageEngine: StorageEngine
        var stateMachine: MockStateMachine<RemoteSyncEngine.State, RemoteSyncEngine.Action>!
        let validAPIPluginKey = "MockAPICategoryPlugin"
        let validAuthPluginKey = "MockAuthCategoryPlugin"
        do {
            let connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)

            let outgoingMutationQueue = NoOpMutationQueue()
            let mutationDatabaseAdapter = try AWSMutationDatabaseAdapter(storageAdapter: storageAdapter)
            let awsMutationEventPublisher = AWSMutationEventPublisher(eventSource: mutationDatabaseAdapter)
            stateMachine = MockStateMachine(initialState: .notStarted,
                                            resolver: RemoteSyncEngine.Resolver.resolve(currentState:action:))

            let syncEngine = RemoteSyncEngine(
                storageAdapter: storageAdapter,
                dataStoreConfiguration: .default,
                outgoingMutationQueue: outgoingMutationQueue,
                mutationEventIngester: mutationDatabaseAdapter,
                mutationEventPublisher: awsMutationEventPublisher,
                initialSyncOrchestratorFactory: NoOpInitialSyncOrchestrator.factory,
                reconciliationQueueFactory: MockAWSIncomingEventReconciliationQueue.factory,
                stateMachine: stateMachine,
                networkReachabilityPublisher: nil,
                requestRetryablePolicy: MockRequestRetryablePolicy()
            )

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
            return storageEngine
        }
        let dataStorePublisher = DataStorePublisher()
        dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestJsonModelRegistration(),
                                             storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                             dataStorePublisher: dataStorePublisher,
                                             validAPIPluginKey: validAPIPluginKey,
                                             validAuthPluginKey: validAuthPluginKey)

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStorePlugin": true
        ])

        // Since these tests use syncable models, we have to set up an API category also
        let apiConfig = APICategoryConfiguration(plugins: ["MockAPICategoryPlugin": true])
        let apiPlugin = MockAPICategoryPlugin()

        let amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: dataStoreConfig)

        do {
            try Amplify.add(plugin: apiPlugin)
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    /// - Given: A configured Amplify system on iOS 13 or higher
    /// - When:
    ///    - I get a publisher observing a model
    /// - Then:
    ///    - I receive notifications for updates to that model
    func testPublisher() {

        let receivedMutationEvent = expectation(description: "Received mutation event")

        let subscription = dataStorePlugin.publisher(for: "Post").sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("Unexpected error: \(error)")
                case .finished:
                    break
                }
            }, receiveValue: { _ in
                receivedMutationEvent.fulfill()
            })

        // insert a post

        let title = "a title"
        let content = "some content"
        let createdAt = Temporal.DateTime.now().iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
        let model = DynamicModel(values: post)
        let postSchema = ModelRegistry.modelSchema(from: "Post")!
        dataStorePlugin.save(model, modelSchema: postSchema) { _ in }
        wait(for: [receivedMutationEvent], timeout: 1.0)
        subscription.cancel()
    }

    /// - Given: A configured Amplify system on iOS 13 or higher
    /// - When:
    ///    - I get a publisher observing all models
    ///    - I perform mutation for Post and Comment
    /// - Then:
    ///    - I receive notifications for updates to both Post and Comment
    func testPublisherWithMultipleCreate() {

        let receivedPostMutationEvent = expectation(description: "Received post mutation event")
        let receivedCommentMutationEvent = expectation(description: "Received Comment mutation event")

        let subscription = dataStorePlugin.publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("Unexpected error: \(error)")
                case .finished:
                    break
                }
            }, receiveValue: { event in
                switch event.modelName {
                case "Post":
                    receivedPostMutationEvent.fulfill()
                case "Comment":
                    receivedCommentMutationEvent.fulfill()
                default:
                    print("Ignore")
                }

            })

        // insert a post
        let title = "a title"
        let content = "some content"
        let createdAt = Temporal.DateTime.now().iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
        let model = DynamicModel(values: post)
        let postSchema = ModelRegistry.modelSchema(from: "Post")!
        dataStorePlugin.save(model, modelSchema: postSchema) { _ in }

        // insert a comment
        let commentContent = "some content"
        let comment = ["content": .string(commentContent),
                    "createdAt": .string(createdAt),
                    "post": .object(model.values)] as [String: JSONValue]
        let commentModel = DynamicModel(values: comment)
        let commentSchema = ModelRegistry.modelSchema(from: "Comment")!
        dataStorePlugin.save(commentModel, modelSchema: commentSchema) { result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let model):
                print(model)
            }
        }

        wait(for: [receivedPostMutationEvent, receivedCommentMutationEvent], timeout: 3.0)
        subscription.cancel()
    }

    /// - Given: A configured DataStore
    /// - When:
    ///    - I subscribe to model events
    /// - Then:
    ///    - I am notified of `create` mutations
    func testCreate() {

        let receivedMutationEvent = expectation(description: "Received mutation event")

        let subscription = dataStorePlugin.publisher(for: "Post").sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("Unexpected error: \(error)")
                case .finished:
                    break
                }
            }, receiveValue: { mutationEvent in
                if mutationEvent.mutationType == MutationEvent.MutationType.create.rawValue {
                    receivedMutationEvent.fulfill()
                }
            })

        let title = "a title"
        let content = "some content"
        let createdAt = Temporal.DateTime.now().iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
        let model = DynamicModel(values: post)
        let postSchema = ModelRegistry.modelSchema(from: "Post")!
        dataStorePlugin.save(model, modelSchema: postSchema) { _ in }
        wait(for: [receivedMutationEvent], timeout: 1.0)

        subscription.cancel()
    }

    /// - Given: A configured DataStore
    /// - When:
    ///    - I subscribe to model events
    /// - Then:
    ///    - I am notified of `update` mutations
    func testUpdate() {
        let originalContent = "Content as of \(Date())"
        let title = "a title"
        let createdAt = Temporal.DateTime.now().iso8601String
        let post = ["title": .string(title),
                    "content": .string(originalContent),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
        let model = DynamicModel(values: post)
        let postSchema = ModelRegistry.modelSchema(from: "Post")!

        let saveCompleted = expectation(description: "Save complete")
        dataStorePlugin.save(model, modelSchema: postSchema) { _ in
            saveCompleted.fulfill()
        }

        wait(for: [saveCompleted], timeout: 5.0)

        let newContent = "Updated content as of \(Date())"
        var newModel = model
        newModel.values["content"] = JSONValue.string(newContent)
        newModel.values["createdAt"] = JSONValue.string(Temporal.DateTime.now().iso8601String)

        let receivedMutationEvent = expectation(description: "Received mutation event")

        let subscription = dataStorePlugin.publisher(for: "Post").sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("Unexpected error: \(error)")
                case .finished:
                    break
                }
            }, receiveValue: { mutationEvent in
                if mutationEvent.mutationType == MutationEvent.MutationType.update.rawValue {
                    receivedMutationEvent.fulfill()
                }
            })

        dataStorePlugin.save(newModel, modelSchema: postSchema) { _ in }

        wait(for: [receivedMutationEvent], timeout: 1.0)

        subscription.cancel()
    }

    /// - Given: A configured DataStore
    /// - When:
    ///    - I subscribe to model events
    /// - Then:
    ///    - I am notified of `delete` mutations
    func testDelete() {
        let receivedMutationEvent = expectation(description: "Received mutation event")

        let subscription = dataStorePlugin.publisher(for: "Post").sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("Unexpected error: \(error)")
                case .finished:
                    break
                }
            }, receiveValue: { mutationEvent in
                if mutationEvent.mutationType == MutationEvent.MutationType.delete.rawValue {
                    receivedMutationEvent.fulfill()
                }
            })

        let title = "a title"
        let content = "some content"
        let createdAt = Temporal.DateTime.now().iso8601String
        let post = ["title": .string(title),
                    "content": .string(content),
                    "createdAt": .string(createdAt)] as [String: JSONValue]
        let model = DynamicModel(values: post)
        let postSchema = ModelRegistry.modelSchema(from: "Post")!
        dataStorePlugin.save(model, modelSchema: postSchema) { _ in }

        dataStorePlugin.delete(model, modelSchema: postSchema) { _ in }
        wait(for: [receivedMutationEvent], timeout: 1.0)

        subscription.cancel()
    }
}
