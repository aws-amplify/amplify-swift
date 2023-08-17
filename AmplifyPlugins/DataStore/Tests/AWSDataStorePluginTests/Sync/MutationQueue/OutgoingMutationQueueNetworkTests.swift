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
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStorePlugin
@_implementationOnly import AmplifyAsyncTesting

class OutgoingMutationQueueNetworkTests: SyncEngineTestBase {

    var cancellables: Set<AnyCancellable>!

    var reachabilitySubject: CurrentValueSubject<ReachabilityUpdate, Never>!

    let dbFile: URL = {
        let tempDir = FileManager.default.temporaryDirectory
        let dbName = "OutgoingMutationQueueNetworkTests.db"
        let dbFile = tempDir.appendingPathComponent(dbName)
        return dbFile
    }()

    func getDBConnection(inMemory: Bool) throws -> Connection {
        if inMemory {
            return try Connection(.inMemory)
        } else {
            return try Connection(dbFile.path)
        }
    }

    let connectionError: APIError = {
        APIError.networkError(
            "TEST: Network not available",
            nil,
            URLError(.notConnectedToInternet)
        )
    }()

    override func setUpWithError() throws {
        cancellables = []

        // For this test, we want the network to be initially available. We'll set it to unavailable
        // later in the test to simulate a loss of connectivity after the initial create mutation.
        reachabilitySubject = CurrentValueSubject(ReachabilityUpdate(isOnline: true))
        reachabilityPublisher = reachabilitySubject.eraseToAnyPublisher()
        try super.setUpWithError()

        // Ignore failures -- we don't care if the file didn't exist prior to this test, and if
        // it can't write, the tests will fail elsewhere
        try? FileManager.default.removeItem(at: dbFile)

        let connection = try getDBConnection(inMemory: true)
        try setUpStorageAdapter(connection: connection)

        let mutationQueue = OutgoingMutationQueue(
            storageAdapter: storageAdapter,
            dataStoreConfiguration: .default,
            authModeStrategy: AWSDefaultAuthModeStrategy()
        )
        try setUpDataStore(mutationQueue: mutationQueue)
        ModelRegistry.register(modelType: Post.self)
    }

    override func tearDownWithError() throws {
        cancellables = []
        try super.tearDownWithError()
    }

    /// - Given: A sync-configured DataStore, running without a network connection
    /// - When:
    ///   - I make multiple mutations to a single model
    ///   - I wait long enough for the first mutation to be in a "scheduledRetry" state
    ///   - I make a final update
    ///   - I restore the network
    /// - Then:
    ///   - The sync engine submits the most recent update to the service
    func testLastMutationSentWhenNoNetwork() async throws {
        // NOTE: The state descriptions in this test are approximate, especially as regards the
        // values of the MutationEvent table. Processing happens asynchronously, so it is important
        // to only assert the behavior we care about (which is that the final update happens after
        // network is restored).

        var post = Post(title: "Test", content: "Newly created", createdAt: .now())
        let expectedFinalContent = "FINAL UPDATE"
        let version = AtomicValue(initialValue: 0)

        // Set up API responder chain

        // The first response is a success for the initial "Create" mutation
        let apiRespondedWithSuccess = expectation(description: "apiRespondedWithSuccess")
        let acceptInitialMutation = setUpInitialMutationRequestResponder(
            for: try post.eraseToAnyModel(),
            fulfilling: apiRespondedWithSuccess,
            incrementing: version
        )

        // This response rejects mutations with a retriable error. This will cause the
        // SyncMutationToCloudOperation to schedule a retry for some future date (a few dozen
        // milliseconds in the future, for the first one). By that time, we will have enqueued new
        // mutations, at which point we can resume internet connectivity and ensure the API gets
        // called with the latest mutation. The delay simulates network time--this is to allow us
        // to add mutations to the pending queue while there is one in process.
        let rejectMutationsWithRetriableError = setUpRetriableErrorRequestResponder(
            listenerDelay: 0.25
        )

        // Start by accepting the initial "create" mutation
        apiPlugin.responders = [.mutateRequestListener: acceptInitialMutation]

        try await startAmplifyAndWaitForSync()

        // Save initial model
        let createdNewItem = expectation(description: "createdNewItem")
        let postCopy = post
        Task {
            _ = try await Amplify.DataStore.save(postCopy)
            createdNewItem.fulfill()
        }
        await fulfillment(of: [createdNewItem])
        await fulfillment(of: [apiRespondedWithSuccess], timeout: 1.0, enforceOrder: false)

        // Set the responder to reject the mutation. Make sure to push a retry advice before sending
        // a new mutation.
        apiPlugin.responders = [.mutateRequestListener: rejectMutationsWithRetriableError]

        // NOTE: This policy is not used by the SyncMutationToCloudOperation, only by the
        // RemoteSyncEngine.
        requestRetryablePolicy
            .pushOnRetryRequestAdvice(
                response: RequestRetryAdvice(
                    shouldRetry: true,
                    retryInterval: .seconds(100)
                )
            )

        // We expect this to be picked up by the OutgoingMutationQueue since the network is still
        // available. However, the mutation will be rejected with a retriable error. That retry
        // will be scheduled and probably in "waiting" mode when we send the network unavailable
        // notification below.
        post.content = "Update 1"
        let savedUpdate1 = expectation(description: "savedUpdate1")
        let postCopy1 = post
        Task {
            _ = try await Amplify.DataStore.save(postCopy1)
            savedUpdate1.fulfill()
        }
        await fulfillment(of: [savedUpdate1])

        // At this point, the MutationEvent table (the backing store for the outgoing mutation
        // queue) has only a record for the interim update. It is marked as `inProcess: true`,
        // because the mutation queue is operational and will have picked up the item and attempted
        // to sync it to the cloud.

        // "Turn off" network. The `mockSendCompletion` notifies each subscription listener of a
        // connection error, which will cause the state machine to clean up. As part of cleanup,
        // the RemoteSyncEngine will stop the outgoing mutation queue. We will set the retry
        // advice interval to be very high, so it will be preempted by the "network available"
        // message we send later.
        
        let networkUnavailable = expectation(description: "networkUnavailable")
        setUpNetworkUnavailableListener(
            fulfillingWhenNetworkUnavailable: networkUnavailable
        )

        reachabilitySubject.send(ReachabilityUpdate(isOnline: false))
        let noNetworkCompletion = Subscribers
            .Completion<DataStoreError>
            .failure(.sync("Test", "test", connectionError))
        MockAWSIncomingEventReconciliationQueue.mockSendCompletion(completion: noNetworkCompletion)

        // Assert that DataStore has pushed the no-network event. This isn't strictly necessary for
        // correct operation of the queue.
        await fulfillment(of: [networkUnavailable], timeout: 1.0)

        // At this point, the MutationEvent table has only a record for update1. It is marked as
        // `inProcess: false`, because the mutation queue has been fully cancelled by the cleanup
        // process.

        // Submit two more mutations. The second mutation will overwrite the "initial updated
        // content" record with new "interim" content. Neither of those will be processed by the
        // outgoing mutation queue, since the network is not available and the OutgoingMutationQueue
        // was stopped during cleanup above.

        // We expect this to be written to the queue, overwriting the existing initial update. We
        // also expect that it will be overwritten by the next mutation, without ever being synced
        // to the service.
        post.content = "Update 2"
        let savedUpdate2 = expectation(description: "savedUpdate2")
        let postCopy2 = post
        Task {
            _ = try await Amplify.DataStore.save(postCopy2)
            savedUpdate2.fulfill()
        }
        await fulfillment(of: [savedUpdate2])

        // At this point, the MutationEvent table has only a record for update2. It is marked as
        // `inProcess: false`, because the mutation queue has been fully cancelled.

        // Write another mutation. The current disposition behavior is that the system detects
        // a not-in-process mutation in the queue, and overwrites it with this data. The
        // reconciliation logic drops all but the oldest not-in-process mutations, which means that
        // even if there were multiple not-in-process mutations, after the reconciliation completes
        // there would only be one record in the MutationEvent table.
        post.content = expectedFinalContent
        let savedFinalUpdate = expectation(description: "savedFinalUpdate")
        let postCopy3 = post
        Task {
            _ = try await Amplify.DataStore.save(postCopy3)
            savedFinalUpdate.fulfill()
        }
        await fulfillment(of: [savedFinalUpdate])

        let syncStarted = expectation(description: "syncStarted")
        setUpSyncStartedListener(
            fulfillingWhenSyncStarted: syncStarted
        )

        let outboxEmpty = expectation(description: "outboxEmpty")
        setUpOutboxEmptyListener(
            fulfillingWhenOutboxEmpty: outboxEmpty
        )
        
        // Once we've rejected some mutations due to an unreachable network, we'll allow the final
        // mutation to succeed. This is where we will assert that we've seen the last mutation
        // to be processed
        let expectedFinalContentReceived = expectation(description: "expectedFinalContentReceived")
        let acceptSubsequentMutations = setUpSubsequentMutationRequestResponder(
            for: try post.eraseToAnyModel(),
            fulfilling: expectedFinalContentReceived,
            whenContentContains: expectedFinalContent,
            incrementing: version
        )

        // Turn on network. This will preempt the retry timer and immediately start processing
        // the queue. We expect the mutation queue to restart, poll the MutationEvent table, pick
        // up the final update, and process it.
        let networkAvailableAgain = expectation(description: "networkAvailableAgain")

        setUpNetworkAvailableListener(
            fulfillingWhenNetworkAvailableAgain: networkAvailableAgain
        )
        
        apiPlugin.responders = [.mutateRequestListener: acceptSubsequentMutations]
        reachabilitySubject.send(ReachabilityUpdate(isOnline: true))
        await fulfillment(
            of: [
                syncStarted,
                outboxEmpty,
                expectedFinalContentReceived,
                networkAvailableAgain
            ],
            timeout: 5.0
        )
    }

    // MARK: - Utilities

    private func setUpInitialMutationRequestResponder(
        for model: AnyModel,
        fulfilling expectation: XCTestExpectation,
        incrementing version: AtomicValue<Int>
    ) -> MutateRequestListenerResponder<MutationSync<AnyModel>> {
        MutateRequestListenerResponder<MutationSync<AnyModel>> { _, eventListener in
            let mockResponse = MutationSync(
                model: model,
                syncMetadata: MutationSyncMetadata(
                    modelId: model.id,
                    modelName: model.modelName,
                    deleted: false,
                    lastChangedAt: Date().unixSeconds,
                    version: version.increment()
                )
            )

            DispatchQueue.global().async {
                eventListener?(.success(.success(mockResponse)))
                expectation.fulfill()
            }

            return nil
        }
    }

    /// Returns a responder that executes the eventListener after a delay, to simulate network lag
    private func setUpRetriableErrorRequestResponder(
        listenerDelay: TimeInterval
    ) -> MutateRequestListenerResponder<MutationSync<AnyModel>> {
        MutateRequestListenerResponder<MutationSync<AnyModel>> { _, eventListener in
            DispatchQueue.global().asyncAfter(deadline: .now() + listenerDelay) {
                eventListener?(.failure(self.connectionError))
            }
            return nil
        }
    }

    private func setUpSubsequentMutationRequestResponder(
        for model: AnyModel,
        fulfilling expectation: XCTestExpectation,
        whenContentContains expectedFinalContent: String,
        incrementing version: AtomicValue<Int>
    ) -> MutateRequestListenerResponder<MutationSync<AnyModel>> {
        MutateRequestListenerResponder<MutationSync<AnyModel>> { request, eventListener in
            guard let input = request.variables?["input"] as? [String: Any],
                  let content = input["content"] as? String else {
                XCTFail("Unexpected request structure: no `content` in variables.")
                return nil
            }

            let mockResponse = MutationSync(
                model: model,
                syncMetadata: MutationSyncMetadata(
                    modelId: model.id,
                    modelName: model.modelName,
                    deleted: false,
                    lastChangedAt: Date().unixSeconds,
                    version: version.increment()
                )
            )

            eventListener?(.success(.success(mockResponse)))

            if content == expectedFinalContent {
                expectation.fulfill()
            }

            return nil
        }

    }

    private func setUpNetworkUnavailableListener(
        fulfillingWhenNetworkUnavailable networkUnavailable: XCTestExpectation
    ) {
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .print("### DataStore listener \(Date()) - ")
            .filter { $0.eventName == HubPayload.EventName.DataStore.networkStatus }
            .sink { payload in
                guard let networkStatusEvent = payload.data as? NetworkStatusEvent else {
                    XCTFail("Failed to cast payload data as NetworkStatusEvent")
                    return
                }

                if !networkStatusEvent.active {
                    networkUnavailable.fulfill()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setUpNetworkAvailableListener(
        fulfillingWhenNetworkAvailableAgain networkAvailableAgain: XCTestExpectation
    ) {
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .print("### DataStore listener \(Date()) - ")
            .filter { $0.eventName == HubPayload.EventName.DataStore.networkStatus }
            .sink { payload in
                guard let networkStatusEvent = payload.data as? NetworkStatusEvent else {
                    XCTFail("Failed to cast payload data as NetworkStatusEvent")
                    return
                }
                
                if networkStatusEvent.active {
                    networkAvailableAgain.fulfill()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setUpSyncStartedListener(
        fulfillingWhenSyncStarted syncStarted: XCTestExpectation
    ) {
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncStarted }
            .sink { _ in syncStarted.fulfill() }
            .store(in: &cancellables)
    }

    private func setUpOutboxEmptyListener(
        fulfillingWhenOutboxEmpty outboxEmpty: XCTestExpectation
    ) {
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.outboxStatus }
            .sink { payload in
                guard let outboxStatusEvent = payload.data as? OutboxStatusEvent else {
                    XCTFail("Failed to cast payload data as OutboxStatusEvent")
                    return
                }
                if outboxStatusEvent.isEmpty {
                    outboxEmpty.fulfill()
                }
            }
            .store(in: &cancellables)
    }

}
