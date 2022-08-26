//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite

import Combine
@testable import Amplify
@testable import AWSPluginsCore
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

/// Tests behavior of local DataStore subscriptions (as opposed to remote API subscription behaviors)
class LocalSubscriptionTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()

        await Amplify.reset()
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
                authModeStrategy: AWSDefaultAuthModeStrategy(),
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
        let dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
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
    func testPublisher() async throws {
        let receivedMutationEvent = expectation(description: "Received mutation event")

        let subscription = Task {
            let mutationEvents = Amplify.DataStore.observe(for: Post.self)
            do {
                for try await _ in mutationEvents {
                    receivedMutationEvent.fulfill()
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        
        
//        let subscription = Amplify.DataStore.publisher(for: Post.self).sink(
//            receiveCompletion: { completion in
//                switch completion {
//                case .failure(let error):
//                    XCTFail("Unexpected error: \(error)")
//                case .finished:
//                    break
//                }
//        }, receiveValue: { _ in
//            receivedMutationEvent.fulfill()
//        })

        let model = Post(id: UUID().uuidString,
                         title: "Test Post",
                         content: "Test Post Content",
                         createdAt: .now(),
                         updatedAt: nil,
                         draft: false,
                         rating: nil,
                         comments: [])

        _ = try await Amplify.DataStore.save(model)
        wait(for: [receivedMutationEvent], timeout: 1.0)
        subscription.cancel()
    }

    /// - Given: A configured DataStore
    /// - When:
    ///    - I subscribe to model events
    /// - Then:
    ///    - I am notified of `create` mutations
    func testCreate() async throws {
        let receivedMutationEvent = expectation(description: "Received mutation event")

        let subscription = Task {
            let mutationEvents = Amplify.DataStore.observe(for: Post.self)
            do {
                for try await mutationEvent in mutationEvents {
                    if mutationEvent.mutationType == MutationEvent.MutationType.create.rawValue {
                        receivedMutationEvent.fulfill()
                    }
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
//        let subscription = Amplify.DataStore.publisher(for: Post.self).sink(
//            receiveCompletion: { completion in
//                switch completion {
//                case .failure(let error):
//                    XCTFail("Unexpected error: \(error)")
//                case .finished:
//                    break
//                }
//        }, receiveValue: { mutationEvent in
//            if mutationEvent.mutationType == MutationEvent.MutationType.create.rawValue {
//                receivedMutationEvent.fulfill()
//            }
//        })

        let model = Post(id: UUID().uuidString,
                         title: "Test Post",
                         content: "Test Post Content",
                         createdAt: .now(),
                         updatedAt: nil,
                         draft: false,
                         rating: nil,
                         comments: [])

        _ = try await Amplify.DataStore.save(model)
        wait(for: [receivedMutationEvent], timeout: 1.0)

        subscription.cancel()
    }

    /// - Given: A configured DataStore
    /// - When:
    ///    - I subscribe to model events
    /// - Then:
    ///    - I am notified of `update` mutations
    func testUpdate() async throws {
        let originalContent = "Content as of \(Date())"
        let model = Post(id: UUID().uuidString,
                         title: "Test Post",
                         content: originalContent,
                         createdAt: .now(),
                         updatedAt: nil,
                         draft: false,
                         rating: nil,
                         comments: [])

        _ = try await Amplify.DataStore.save(model)

        let newContent = "Updated content as of \(Date())"
        var newModel = model
        newModel.content = newContent
        newModel.updatedAt = .now()

        let receivedMutationEvent = expectation(description: "Received mutation event")

        let subscription = Task {
            let mutationEvents = Amplify.DataStore.observe(for: Post.self)
            do {
                for try await _ in mutationEvents {
                    receivedMutationEvent.fulfill()
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        
//        let subscription = Amplify.DataStore.publisher(for: Post.self).sink(
//            receiveCompletion: { completion in
//                switch completion {
//                case .failure(let error):
//                    XCTFail("Unexpected error: \(error)")
//                case .finished:
//                    break
//                }
//        }, receiveValue: { mutationEvent in
//            if mutationEvent.mutationType == MutationEvent.MutationType.update.rawValue {
//                receivedMutationEvent.fulfill()
//            }
//        })
        
        _ = try await Amplify.DataStore.save(newModel)

        wait(for: [receivedMutationEvent], timeout: 1.0)

        subscription.cancel()
    }

    /// - Given: A configured DataStore
    /// - When:
    ///    - I subscribe to model events
    /// - Then:
    ///    - I am notified of `delete` mutations
    func testDelete() async throws {
        let receivedMutationEvent = expectation(description: "Received mutation event")

        let subscription = Task {
            let mutationEvents = Amplify.DataStore.observe(for: Post.self)
            do {
                for try await mutationEvent in mutationEvents {
                    if mutationEvent.mutationType == MutationEvent.MutationType.delete.rawValue {
                        receivedMutationEvent.fulfill()
                    }
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        
//        let subscription = Amplify.DataStore.publisher(for: Post.self).sink(
//            receiveCompletion: { completion in
//                switch completion {
//                case .failure(let error):
//                    XCTFail("Unexpected error: \(error)")
//                case .finished:
//                    break
//                }
//        }, receiveValue: { mutationEvent in
//            if mutationEvent.mutationType == MutationEvent.MutationType.delete.rawValue {
//                receivedMutationEvent.fulfill()
//            }
//        })

        let model = Post(title: "Test Post",
                         content: "Test Post Content",
                         createdAt: .now())

        _ = try await Amplify.DataStore.save(model)
        _ = try await Amplify.DataStore.delete(model)
        wait(for: [receivedMutationEvent], timeout: 1.0)

        subscription.cancel()
    }

}
