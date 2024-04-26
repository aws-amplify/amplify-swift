//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStorePlugin

class OutgoingMutationQueueTests: SyncEngineTestBase {

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I invoke DataStore.save() for a new model
    /// - Then:
    ///    - The outgoing mutation queue sends a create mutation
    func testMutationQueueCreateSendsSync() async throws {

        await tryOrFail {
            try setUpStorageAdapter()
            try setUpDataStore(
                mutationQueue: OutgoingMutationQueue(
                    storageAdapter: storageAdapter,
                    dataStoreConfiguration: .testDefault(),
                    authModeStrategy: AWSDefaultAuthModeStrategy()
                )
            )
        }

        let post = Post(title: "Post title", content: "Post content", createdAt: .now())
        let outboxStatusReceivedCurrentCount = AtomicValue(initialValue: 0)
        let outboxStatusOnStart = expectation(description: "On DataStore start, outboxStatus received")
        let outboxStatusOnMutationEnqueued = expectation(description: "Mutation enqueued, outboxStatus received")
        let outboxMutationEnqueued = expectation(description: "Mutation enqueued, outboxMutationEnqueued received")

        let hubListener0 = Amplify.Hub.listen(to: .dataStore, eventName: HubPayload.EventName.DataStore.outboxStatus) { payload in
            defer { _ = outboxStatusReceivedCurrentCount.increment(by: 1) }
            guard let outboxStatusEvent = payload.data as? OutboxStatusEvent else {
                XCTFail("Failed to cast payload data as OutboxStatusEvent")
                return
            }

            switch outboxStatusReceivedCurrentCount.get() {
            case 0:
                XCTAssertTrue(outboxStatusEvent.isEmpty)
                outboxStatusOnStart.fulfill()
            case 1:
                XCTAssertFalse(outboxStatusEvent.isEmpty)
                outboxStatusOnMutationEnqueued.fulfill()
            case 2:
                XCTAssertTrue(outboxStatusEvent.isEmpty)
            default:
                XCTFail("Should not trigger outbox status event")
            }
        }

        let hubListener1 = Amplify.Hub.listen(to: .dataStore, eventName: HubPayload.EventName.DataStore.outboxMutationEnqueued) { payload in
            guard let outboxStatusEvent = payload.data as? OutboxMutationEvent else {
                XCTFail("Failed to cast payload data as OutboxMutationEvent")
                return
            }
            XCTAssertEqual(outboxStatusEvent.modelName, "Post")
            outboxMutationEnqueued.fulfill()
        }

        guard try await HubListenerTestUtilities.waitForListener(with: hubListener0, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        guard try await HubListenerTestUtilities.waitForListener(with: hubListener1, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        let createMutationSent = expectation(description: "Create mutation sent to API category")
        apiPlugin.listeners.append { message in
            if message.contains("createPost") && message.contains(post.id) {
                createMutationSent.fulfill()
            }
        }

        apiPlugin.responders[.mutateRequestResponse] = MutateRequestResponder { request in
            let anyModel = try! post.eraseToAnyModel()
            let remoteSyncMetadata = MutationSyncMetadata(
                modelId: post.id,
                modelName: Post.modelName,
                deleted: false,
                lastChangedAt: Date().unixSeconds,
                version: 2
            )
            let remoteMutationSync = MutationSync(model: anyModel, syncMetadata: remoteSyncMetadata)
            return .success(remoteMutationSync)
        }

        try await startAmplifyAndWaitForSync()

        let saveSuccess = expectation(description: "save success")
        Task {
            _ = try await Amplify.DataStore.save(post)
            saveSuccess.fulfill()
        }

        await fulfillment(
            of: [
                saveSuccess,
                outboxStatusOnStart,
                outboxStatusOnMutationEnqueued,
                outboxMutationEnqueued,
                createMutationSent
            ],
            timeout: 5.0
        )
        Amplify.Hub.removeListener(hubListener0)
        Amplify.Hub.removeListener(hubListener1)
    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I invoke DataStore.delete()
    /// - Then:
    ///    - The mutation queue writes events
    func testMutationQueueStoresDeleteEvents() throws {
        throw XCTSkip("Not yet implemented")
    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I start syncing with mutation events already in the database
    ///    - keep the mutaiton sync request in process
    /// - Then:
    ///    - The mutation queue delivers the first previously loaded event
    func testMutationQueueLoadsPendingMutations() async throws {
        let timeout: TimeInterval = 5
        await tryOrFail {
            try setUpStorageAdapter()
        }

        // pre-load the MutationEvent table with mutation data
        let mutationEventSaved = expectation(description: "Preloaded mutation event saved")
        mutationEventSaved.expectedFulfillmentCount = 2

        let posts = (1...2).map { Post(
            id: "pendingPost-\($0)",
            title: "pendingPost-\($0) title",
            content: "pendingPost-\($0) content",
            createdAt: .now()
        )}

        let postMutationEvents = try posts.map {
            let pendingPostJSON = try $0.toJSON()
            return MutationEvent(
                id: "mutation-\($0.id)",
                modelId: $0.id,
                modelName: Post.modelName,
                json: pendingPostJSON,
                mutationType: .create,
                createdAt: .now()
            )
        }

        apiPlugin.responders[.mutateRequestResponse] = MutateRequestResponder<MutationSync<AnyModel>> { request in
            if let variables = request.variables?["input"] as? [String: Any],
               let postId = variables["id"] as? String,
               let post = posts.first(where: { $0.id == postId })
            {
                try? await Task.sleep(seconds: timeout + 1)
                let anyModel = try! post.eraseToAnyModel()
                let remoteSyncMetadata = MutationSyncMetadata(modelId: post.id,
                                                              modelName: Post.modelName,
                                                              deleted: false,
                                                              lastChangedAt: Date().unixSeconds,
                                                              version: 2)
                let remoteMutationSync = MutationSync(model: anyModel, syncMetadata: remoteSyncMetadata)
                return .success(remoteMutationSync)
            }
            return .failure(.unknown("No matching post found", "", nil))
        }


        postMutationEvents.forEach { event in
            storageAdapter.save(event) { result in
                switch result {
                case .failure(let dataStoreError):
                    XCTFail(String(describing: dataStoreError))
                case .success:
                    mutationEventSaved.fulfill()
                }
            }
        }

        await fulfillment(of: [mutationEventSaved], timeout: 1.0)

        var outboxStatusReceivedCurrentCount = 0
        let outboxStatusOnStart = expectation(description: "On DataStore start, outboxStatus received")
        let outboxStatusOnMutationEnqueued = expectation(description: "Mutation enqueued, outboxStatus received")

        let filter = HubFilters.forEventName(HubPayload.EventName.DataStore.outboxStatus)
        let hubListener = Amplify.Hub.listen(to: .dataStore, isIncluded: filter) { payload in
            outboxStatusReceivedCurrentCount += 1
            guard let outboxStatusEvent = payload.data as? OutboxStatusEvent else {
                XCTFail("Failed to cast payload data as OutboxStatusEvent")
                return
            }

            switch outboxStatusReceivedCurrentCount {
            case 1:
                XCTAssertFalse(outboxStatusEvent.isEmpty)
                outboxStatusOnStart.fulfill()
            case 2:
                XCTAssertFalse(outboxStatusEvent.isEmpty)
                outboxStatusOnMutationEnqueued.fulfill()
            default:
                XCTFail("Should not trigger outbox status event")
            }

        }

        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        let mutation1Sent = expectation(description: "Create mutation 1 sent to API category")
        let mutation2Sent = expectation(description: "Create mutation 2 sent to API category")
        mutation2Sent.isInverted = true
        apiPlugin.listeners.append { message in
            if message.contains("createPost") && message.contains("pendingPost-1") {
                mutation1Sent.fulfill()
            } else if message.contains("createPost") && message.contains("pendingPost-2") {
                mutation2Sent.fulfill()
            }
        }

        await tryOrFail {
            try setUpDataStore(mutationQueue: OutgoingMutationQueue(storageAdapter: storageAdapter,
                                                                    dataStoreConfiguration: .testDefault(),
                                                                    authModeStrategy: AWSDefaultAuthModeStrategy()))
            try await startAmplify()
        }

        await fulfillment(of: [
            outboxStatusOnStart,
            outboxStatusOnMutationEnqueued,
            mutation1Sent,
            mutation2Sent
        ], timeout: timeout)

        Amplify.Hub.removeListener(hubListener)
    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I start syncing with mutation events already in the database
    ///    - I add mutations before the pending mutations have been processed
    /// - Then:
    ///    - The mutation queue delivers events in FIFO order
    func testMutationQueueDeliversPendingMutationsFirst() throws {
        throw XCTSkip("Not yet implemented")
    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I successfully process a mutation
    /// - Then:
    ///    - The mutation queue deletes the event from its persistent store
    func testMutationQueueDequeuesSavedEvents() throws {
        throw XCTSkip("Not yet implemented")
    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I successfully process a mutation
    /// - Then:
    ///    - The mutation listener is unsubscribed from Hub
    func testLocalMutationUnsubcsribesFromCloud() throws {
        throw XCTSkip("Not yet implemented")
    }

}
