//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SQLite
import XCTest
import Combine

@testable import Amplify
@testable import AWSPluginsCore
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

/// Base class for SyncEngine and sync-enabled DataStore tests
class SyncEngineTestBase: XCTestCase {

    /// Populated during setUp, used in each test during `Amplify.configure()`
    var amplifyConfig: AmplifyConfiguration!

    /// Mock used to listen for API calls; this is how we assert that syncEngine is delivering events to the API
    var apiPlugin: MockAPICategoryPlugin!

    /// Mock used to listen for Auth calls; this is how we assert that syncEngine is checking authentication state
    var authPlugin: MockAuthCategoryPlugin!

    /// Used for DB manipulation to mock starting data for tests
    var storageAdapter: SQLiteStorageEngineAdapter!

    var stateMachine: StateMachine<RemoteSyncEngine.State, RemoteSyncEngine.Action>!

    var reachabilityPublisher: AnyPublisher<ReachabilityUpdate, Never>?

    var syncEngine: RemoteSyncEngineBehavior!

    var remoteSyncEngineSink: AnyCancellable!

    var requestRetryablePolicy: MockRequestRetryablePolicy!
    
    var token: UnsubscribeToken!

    // MARK: - Setup

    override func setUp() async throws {
        continueAfterFailure = false

        await Amplify.reset()

        let apiConfig = APICategoryConfiguration(plugins: [
            "MockAPICategoryPlugin": true
        ])

        let authConfig = AuthCategoryConfiguration(plugins: [
            "MockAuthCategoryPlugin": true
        ])

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStorePlugin": true
        ])

        requestRetryablePolicy = MockRequestRetryablePolicy()

        amplifyConfig = AmplifyConfiguration(api: apiConfig, auth: authConfig, dataStore: dataStoreConfig)

        if let reachabilityPublisher = reachabilityPublisher {
            apiPlugin = MockAPICategoryPlugin(
                reachabilityPublisher: reachabilityPublisher
            )
        } else {
            apiPlugin = MockAPICategoryPlugin()
        }

        authPlugin = MockAuthCategoryPlugin()
        try Amplify.add(plugin: apiPlugin)
        try Amplify.add(plugin: authPlugin)
        Amplify.Logging.logLevel = .verbose
    }
    
    override func tearDown() async throws {
        amplifyConfig = nil
        apiPlugin = nil
        authPlugin = nil
        storageAdapter = nil
        stateMachine = nil
        reachabilityPublisher = nil
        syncEngine = nil
        remoteSyncEngineSink = nil
        requestRetryablePolicy = nil
        token = nil
        await Amplify.reset()
    }

    /// Sets up a StorageAdapter backed by `connection`. Optionally registers and sets up models in
    /// `models`.
    /// - Parameters:
    ///   - models: models to pre-create. Defaults to empty array
    ///   - connection: SQLite Connection for the database. defaults to an in-memory connection
    func setUpStorageAdapter(
        preCreating models: [Model.Type] = [],
        connection: Connection? = nil
    ) throws {
        models.forEach { ModelRegistry.register(modelType: $0) }
        let resolvedConnection: Connection
        if let connection = connection {
            resolvedConnection = connection
        } else {
            resolvedConnection = try Connection(.inMemory)
        }

        storageAdapter = try SQLiteStorageEngineAdapter(connection: resolvedConnection)
        try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas + models.map { $0.schema })
    }

    /// Sets up a DataStorePlugin backed by the storageAdapter created in `setUpStorageAdapter()`, and an optional
    /// `mutationQueue`. If no mutationQueue is specified, uses  NoOpMutationQueue, meaning that incoming subscription
    /// events will never be delivered to the sync engine.
    func setUpDataStore(
        mutationQueue: OutgoingMutationQueueBehavior = NoOpMutationQueue(),
        initialSyncOrchestratorFactory: @escaping InitialSyncOrchestratorFactory = NoOpInitialSyncOrchestrator.factory,
        modelRegistration: AmplifyModelRegistration = TestModelRegistration()
    ) throws {
        let mutationDatabaseAdapter = try AWSMutationDatabaseAdapter(storageAdapter: storageAdapter)
        let awsMutationEventPublisher = AWSMutationEventPublisher(eventSource: mutationDatabaseAdapter)
        stateMachine = StateMachine(initialState: .notStarted,
                                    resolver: RemoteSyncEngine.Resolver.resolve(currentState:action:))

        syncEngine = RemoteSyncEngine(storageAdapter: storageAdapter,
                                      dataStoreConfiguration: .default,
                                      authModeStrategy: AWSDefaultAuthModeStrategy(),
                                      outgoingMutationQueue: mutationQueue,
                                      mutationEventIngester: mutationDatabaseAdapter,
                                      mutationEventPublisher: awsMutationEventPublisher,
                                      initialSyncOrchestratorFactory: initialSyncOrchestratorFactory,
                                      reconciliationQueueFactory: MockAWSIncomingEventReconciliationQueue.factory,
                                      stateMachine: stateMachine,
                                      networkReachabilityPublisher: reachabilityPublisher,
                                      requestRetryablePolicy: requestRetryablePolicy)
        remoteSyncEngineSink = syncEngine
            .publisher
            .sink(receiveCompletion: {_ in },
                  receiveValue: { (event: RemoteSyncEngineEvent) in
                    switch event {
                    case .mutationsPaused:
                        // Assume AWSIncomingEventReconciliationQueue succeeds in establishing connections
                        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
                            MockAWSIncomingEventReconciliationQueue.mockSend(event: .initialized)
                        }
                    default:
                        break
                    }
            })

        let validAPIPluginKey = "MockAPICategoryPlugin"
        let validAuthPluginKey = "MockAuthCategoryPlugin"

        let storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                          dataStoreConfiguration: .default,
                                          syncEngine: syncEngine,
                                          validAPIPluginKey: validAPIPluginKey,
                                          validAuthPluginKey: validAuthPluginKey)
        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
            return storageEngine
        }
        let publisher = DataStorePublisher()
        let dataStorePlugin = AWSDataStorePlugin(modelRegistration: modelRegistration,
                                                 storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                                 dataStorePublisher: publisher,
                                                 validAPIPluginKey: validAPIPluginKey,
                                                 validAuthPluginKey: validAuthPluginKey)

        try Amplify.add(plugin: dataStorePlugin)
    }

    /// Starts amplify by invoking `Amplify.configure(amplifyConfig)`
    func startAmplify() throws {
        try Amplify.configure(amplifyConfig)
        Amplify.DataStore.start(completion: {_ in})
    }
    
    private func startAmplifyAndWaitForSync(completion: @escaping (Swift.Result<Void, Error>)->Void) {
        token = Amplify.Hub.listen(to: .dataStore) { [weak self] payload in
            if payload.eventName == "DataStore.syncStarted" {
                if let token = self?.token {
                Amplify.Hub.removeListener(token)
                completion(.success(()))
                }
            }
        }

        do {
            guard try HubListenerTestUtilities.waitForListener(with: token, timeout: 5.0) else {
                XCTFail("Never registered listener for sync started")
                return
            }

            try startAmplify()
        } catch {
            Amplify.Hub.removeListener(token)
            completion(.failure(error))
        }
    }
    
    /// Starts amplify by invoking `Amplify.configure(amplifyConfig)`, and waits to receive a `syncStarted` Hub message
    /// before returning.
    func startAmplifyAndWaitForSync() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            startAmplifyAndWaitForSync { result in
                continuation.resume(with: result)
            }
        }
    }
    

    // MARK: - Data methods

    /// Saves a mutation event directly to StorageAdapter. Used for pre-populating database before tests
    func saveMutationEvent(of mutationType: MutationEvent.MutationType,
                           for post: Post,
                           inProcess: Bool = false) throws {
        let mutationEvent = try MutationEvent(id: SyncEngineTestBase.mutationEventId(for: post),
                                              modelId: post.id,
                                              modelName: post.modelName,
                                              json: post.toJSON(),
                                              mutationType: mutationType,
                                              createdAt: .now(),
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

    /// Saves a Post record directly to StorageAdapter. Used for pre-populating database before tests
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

    // MARK: - Helpers

    static func mutationEventId(for post: Post) -> String {
        "mutation-of-\(post.id)"
    }

}
