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
@testable import AWSDataStoreCategoryPlugin

class OutgoingMutationQueueNetworkTests: SyncEngineTestBase {

    let dbFile: URL = {
        let tempDir = FileManager.default.temporaryDirectory
        let dbName = "OutgoingMutationQueueNetworkTests.db"
        let dbFile = tempDir.appendingPathComponent(dbName)
        return dbFile
    }()

    let connectionError: APIError = {
        APIError.networkError(
            "TEST: Network not available",
            nil,
            URLError(.notConnectedToInternet)
        )
    }()

    override func setUpWithError() throws {
        // For this test, we want the network to be initially available. We'll set it to unavailable
        // later in the test to simulate a loss of connectivity after the initial create mutation.
        reachabilityPublisher = CurrentValueSubject(ReachabilityUpdate(isOnline: true))
        try super.setUpWithError()

        // Ignore failures -- we don't care if the file didn't exist prior to this test, and if
        // it can't write, the tests will fail elsewhere
        try? FileManager.default.removeItem(at: dbFile)

        let connection = try Connection(dbFile.path)
        try setUpStorageAdapter(connection: connection)

        let mutationQueue = OutgoingMutationQueue(
            storageAdapter: storageAdapter,
            dataStoreConfiguration: .default,
            authModeStrategy: AWSDefaultAuthModeStrategy()
        )
        try setUpDataStore(mutationQueue: mutationQueue)
    }

    /// - Given: A sync-configured DataStore, running without a network connection
    /// - When:
    ///   - I make multiple mutations to a single model
    ///   - I wait long enough for the first mutation to be in a "scheduledRetry" state
    ///   - I make a final update
    ///   - I restore the network
    /// - Then:
    ///   - The sync engine submits the most recent update to the service
    func testLastMutationSentWhenNoNetwork() throws {
        var post = Post(title: "Test", content: "Newly created", createdAt: .now())
        let expectedFinalContent = "FINAL UPDATE"
        let version = AtomicValue(initialValue: 0)

        // We expect 2 network available notifications: the initial notification sent from the
        // RemoteSyncEngine when it first `start()`s and subscribes to the reachability publisher,
        // and the notification after we restore connectivity later in the test.
        let shouldFulfillNetworkAvailableAgain = AtomicValue(initialValue: false)
        let networkUnavailable = expectation(description: "networkUnavailable")
        let networkAvailableAgain = expectation(description: "networkAvailableAgain")
        let networkStatusFilter = HubFilters.forEventName(HubPayload.EventName.DataStore.networkStatus)

        let networkStatusListener = Amplify.Hub.listen(
            to: .dataStore,
            isIncluded: networkStatusFilter
        ) { payload in
            guard let networkStatusEvent = payload.data as? NetworkStatusEvent else {
                XCTFail("Failed to cast payload data as NetworkStatusEvent")
                return
            }

            if networkStatusEvent.active {
                if shouldFulfillNetworkAvailableAgain.get() {
                    networkAvailableAgain.fulfill()
                }
            } else {
                // If the received event is an "unavailable" message, we should fulfill the
                // "network available" expectation the next time we receive an "available" message.
                shouldFulfillNetworkAvailableAgain.set(true)
                networkUnavailable.fulfill()
            }
        }

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

        // Once we've rejected one mutation due to an unreachable network, we'll allow subsequent
        // mutations to succeed. This is where we will assert that we've seen the last mutation
        // to be processed
        let expectedFinalContentReceived = expectation(description: "expectedFinalContentReceived")
        let acceptSubsequentMutations = setUpSubsequentMutationRequestResponder(
            for: try post.eraseToAnyModel(),
            fulfilling: expectedFinalContentReceived,
            whenContentContains: expectedFinalContent,
            incrementing: version
        )

        apiPlugin.responders = [.mutateRequestListener: acceptInitialMutation]

        try startAmplifyAndWaitForSync()

        // Save initial model
        let saved1 = expectation(description: "saved1")
        Amplify.DataStore.save(post) {
            if case .failure(let error) = $0 {
                XCTAssertNil(error)
            } else {
                saved1.fulfill()
            }
        }

        wait(for: [saved1, apiRespondedWithSuccess], timeout: 0.1)

        // "Turn off" network and set up responder to reject subsequent requests. Notify each
        // subscription listener of a connection error, which will cause the state machine to
        // clean up.
        requestRetryablePolicy
            .pushOnRetryRequestAdvice(
                response: RequestRetryAdvice(
                    shouldRetry: true,
                    retryInterval: .milliseconds(10)
                )
            )
        apiPlugin.responders = [.mutateRequestListener: rejectMutationsWithRetriableError]
        reachabilityPublisher?.send(ReachabilityUpdate(isOnline: false))
        wait(for: [networkUnavailable], timeout: 0.1)
        let noNetworkCompletion = Subscribers
            .Completion<DataStoreError>
            .failure(.sync("Test", "test", connectionError))
        MockAWSIncomingEventReconciliationQueue.mockSendCompletion(completion: noNetworkCompletion)

        // Submit multiple mutations

        // We expect this to be picked up by the OutgoingMutationQueue right away, but it won't be
        // able to complete because the network is not available. That all happens on a background
        // queue, which means we can continue to save updates locally.
        post.content = "Initial updated content"
        let savedInitialUpdate = expectation(description: "savedInitialUpdate")
        Amplify.DataStore.save(post) {
            if case .failure(let error) = $0 {
                XCTAssertNil(error)
            } else {
                savedInitialUpdate.fulfill()
            }
        }
        wait(for: [savedInitialUpdate], timeout: 0.1)

        // We expect this to be written to the queue as a new record. We also expect that it will
        // be ovewrriten by the next mutation, without ever being synced to the service.
        post.content = "Interim content"
        let savedInterimUpdate = expectation(description: "savedInterimUpdate")
        Amplify.DataStore.save(post) {
            if case .failure(let error) = $0 {
                XCTAssertNil(error)
            } else {
                savedInterimUpdate.fulfill()
            }
        }
        wait(for: [savedInterimUpdate], timeout: 0.1)

        // Send another "no network" error to trigger a cleanup
        requestRetryablePolicy
            .pushOnRetryRequestAdvice(
                response: RequestRetryAdvice(
                    shouldRetry: true,
                    retryInterval: .milliseconds(10)
                )
            )
        MockAWSIncomingEventReconciliationQueue.mockSendCompletion(completion: noNetworkCompletion)

        // TODO: make the retry advice used by the outgoing mutation event injectable, so we don't
        // have to wait an arbitrary amount of time for the exponential backoff to grow to the point
        // where we're comfortable the in-process mutation will be sitting in the pending state.
        let timerExpired = expectation(description: "timerExpired")
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(5)) {
            timerExpired.fulfill()
        }
        wait(for: [timerExpired], timeout: 6.0)

        post.content = expectedFinalContent
        let savedFinalUpdate = expectation(description: "savedFinalUpdate")
        Amplify.DataStore.save(post) {
            if case .failure(let error) = $0 {
                XCTAssertNil(error)
            } else {
                savedFinalUpdate.fulfill()
            }
        }
        wait(for: [savedFinalUpdate], timeout: 0.1)

        // Turn on network. This will preempt the retry timer and immediately start processing
        // the queue. We expect the initial mutation to be processed, along with the last one.
        apiPlugin.responders = [.mutateRequestListener: acceptSubsequentMutations]
        reachabilityPublisher?.send(ReachabilityUpdate(isOnline: true))
        wait(for: [networkAvailableAgain], timeout: 5.0)

        // Assert last mutation is sent
        wait(for: [expectedFinalContentReceived], timeout: 1.0)

        Amplify.Hub.removeListener(networkStatusListener)
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
                    id: model.id,
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
                    id: model.id,
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

}
