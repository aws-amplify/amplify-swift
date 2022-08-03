//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStorePlugin

class ModelSyncedEventEmitterTests: XCTestCase {

    var initialSyncOrchestrator: MockAWSInitialSyncOrchestrator?
    var reconciliationQueue: MockAWSIncomingEventReconciliationQueue?

    override func setUp() {
        initialSyncOrchestrator = MockAWSInitialSyncOrchestrator(dataStoreConfiguration: .default,
                                                                 api: nil,
                                                                 reconciliationQueue: nil,
                                                                 storageAdapter: nil)
        reconciliationQueue = MockAWSIncomingEventReconciliationQueue(modelSchemas: [Post.schema],
                                                                      api: nil,
                                                                      storageAdapter: nil,
                                                                      syncExpressions: [],
                                                                      auth: nil)
        ModelRegistry.register(modelType: Post.self)
    }

    /// The last mutation event from the reconciliation queue should be sent before the model synced event.
    ///
    /// - Given: 5 events during sync, 5 reconciliation events (3 applied, 2 dropped)
    /// - When:
    ///    - The events are sent to the emitter, the events from the emitter are received
    /// - Then:
    ///    - the order of the events received should be all the mutation events followed by the modelSyncedEvent.
    ///
    func testReceiveLastMutationEventBeforeModelSyncedEvent() throws {
        let modelSyncedReceived = expectation(description: "modelSynced received")
        let mutationEventAppliedReceived = expectation(description: "mutationEventApplied received")
        mutationEventAppliedReceived.expectedFulfillmentCount = 3
        let mutationEventDroppedReceived = expectation(description: "mutationEventDropped received")
        mutationEventDroppedReceived.expectedFulfillmentCount = 2
        let anyPostMetadata = MutationSyncMetadata(modelId: "1",
                                                   modelName: Post.modelName,
                                                   deleted: false,
                                                   lastChangedAt: Int(Date().timeIntervalSince1970),
                                                   version: 1)
        let testPost = Post(id: "1", title: "post1", content: "content", createdAt: .now())
        let anyPost = AnyModel(testPost)
        let anyPostMutationSync = MutationSync<AnyModel>(model: anyPost, syncMetadata: anyPostMetadata)
        let postMutationEvent = try MutationEvent(untypedModel: testPost, mutationType: .create)
        var receivedMutationEventsCount = 0
        var modelSyncedEventReceivedLast = false

        let emitter = ModelSyncedEventEmitter(modelSchema: Post.schema,
                                              initialSyncOrchestrator: initialSyncOrchestrator,
                                              reconciliationQueue: reconciliationQueue)

        var emitterSink: AnyCancellable?
        emitterSink = emitter.publisher.sink { _ in
            XCTFail("Should not have completed")
        } receiveValue: { value in
            switch value {
            case .modelSyncedEvent(let modelSyncedEvent):
                let expectedModelSyncedEventPayload = ModelSyncedEvent(modelName: "Post",
                                                                       isFullSync: true,
                                                                       isDeltaSync: false,
                                                                       added: 3,
                                                                       updated: 0,
                                                                       deleted: 0)
                XCTAssertEqual(modelSyncedEvent, expectedModelSyncedEventPayload)
                if receivedMutationEventsCount == 5 {
                    modelSyncedEventReceivedLast = true
                }
                modelSyncedReceived.fulfill()
            case .mutationEventApplied:
                receivedMutationEventsCount += 1
                mutationEventAppliedReceived.fulfill()
            case .mutationEventDropped:
                receivedMutationEventsCount += 1
                mutationEventDroppedReceived.fulfill()
            }
        }

        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.started(modelName: Post.modelName,
                                                                            syncType: .fullSync))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.enqueued(anyPostMutationSync,
                                                                             modelName: Post.modelName))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.enqueued(anyPostMutationSync,
                                                                             modelName: Post.modelName))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.enqueued(anyPostMutationSync,
                                                                             modelName: Post.modelName))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.enqueued(anyPostMutationSync,
                                                                             modelName: Post.modelName))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.enqueued(anyPostMutationSync,
                                                                             modelName: Post.modelName))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.finished(modelName: Post.modelName))
        reconciliationQueue?.incomingEventSubject.send(.mutationEventApplied(postMutationEvent))
        reconciliationQueue?.incomingEventSubject.send(.mutationEventDropped(modelName: Post.modelName))
        reconciliationQueue?.incomingEventSubject.send(.mutationEventApplied(postMutationEvent))
        reconciliationQueue?.incomingEventSubject.send(.mutationEventDropped(modelName: Post.modelName))
        reconciliationQueue?.incomingEventSubject.send(.mutationEventApplied(postMutationEvent))
        waitForExpectations(timeout: 1)
        XCTAssertTrue(modelSyncedEventReceivedLast)
        emitterSink?.cancel()
    }

    /// ModelSyncedEventEmitter should continue to send `mutationEventApplied` and `mutationEventDropped` events even
    /// after ModelSyncedEvent has been emitted.
    ///
    /// - Given: Initial sync enqueue 2 models, then reconcile 8 models (5 applied, 3 dropped)
    /// - When:
    ///    - ModelSyncedEventEmitter processes the enqueued and reconciled models.
    /// - Then:
    ///    - Hub event "ModelSyncedEvent" is sent out and subscriber receives all reconciled events.
    ///
    func testSuccess() throws {
        let modelSyncedReceived = expectation(description: "modelSynced received")
        let mutationEventAppliedReceived = expectation(description: "mutationEventApplied received")
        mutationEventAppliedReceived.expectedFulfillmentCount = 5
        let mutationEventDroppedReceived = expectation(description: "mutationEventDropped received")
        mutationEventDroppedReceived.expectedFulfillmentCount = 3
        let anyPostMetadata = MutationSyncMetadata(id: "1",
                                                   deleted: false,
                                                   lastChangedAt: Int(Date().timeIntervalSince1970),
                                                   version: 1)
        let testPost = Post(id: "1", title: "post1", content: "content", createdAt: .now())
        let anyPost = AnyModel(testPost)
        let anyPostMutationSync = MutationSync<AnyModel>(model: anyPost, syncMetadata: anyPostMetadata)
        let postMutationEvent = try MutationEvent(untypedModel: testPost, mutationType: .create)
        let emitter = ModelSyncedEventEmitter(modelSchema: Post.schema,
                                              initialSyncOrchestrator: initialSyncOrchestrator,
                                              reconciliationQueue: reconciliationQueue)

        var emitterSink: AnyCancellable?
        emitterSink = emitter.publisher.sink { _ in
            XCTFail("Should not have completed")
        } receiveValue: { value in
            switch value {
            case .modelSyncedEvent(let modelSyncedEvent):
                let expectedModelSyncedEventPayload = ModelSyncedEvent(modelName: "Post",
                                                                       isFullSync: true,
                                                                       isDeltaSync: false,
                                                                       added: 2,
                                                                       updated: 0,
                                                                       deleted: 0)
                XCTAssertEqual(modelSyncedEvent, expectedModelSyncedEventPayload)
                modelSyncedReceived.fulfill()
            case .mutationEventApplied:
                mutationEventAppliedReceived.fulfill()
            case .mutationEventDropped:
                mutationEventDroppedReceived.fulfill()
            }
        }

        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.started(modelName: Post.modelName,
                                                                            syncType: .fullSync))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.enqueued(anyPostMutationSync,
                                                                             modelName: Post.modelName))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.enqueued(anyPostMutationSync,
                                                                             modelName: Post.modelName))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.finished(modelName: Post.modelName))
        reconciliationQueue?.incomingEventSubject.send(.mutationEventApplied(postMutationEvent))
        reconciliationQueue?.incomingEventSubject.send(.mutationEventApplied(postMutationEvent))
        reconciliationQueue?.incomingEventSubject.send(.mutationEventApplied(postMutationEvent))
        reconciliationQueue?.incomingEventSubject.send(.mutationEventApplied(postMutationEvent))
        reconciliationQueue?.incomingEventSubject.send(.mutationEventApplied(postMutationEvent))
        reconciliationQueue?.incomingEventSubject.send(.mutationEventDropped(modelName: Post.modelName))
        reconciliationQueue?.incomingEventSubject.send(.mutationEventDropped(modelName: Post.modelName))
        reconciliationQueue?.incomingEventSubject.send(.mutationEventDropped(modelName: Post.modelName))

        waitForExpectations(timeout: 1)
        emitterSink?.cancel()
    }

    /// Send randomly 80% of the events from `initialSyncOrchestrator`, and 20% of the events from
    /// `reconciliationQueue`. This replicates the scenario of concurrent events received by the emitter. Then finished
    /// event from `initialSyncOrchestrator`. Then concurrent send all events from `reconciliationQueue`, one of these
    /// events will resolve to dispatching the modelSyncedEvent, followed by the remaining events being sent back from
    /// the emitter's topic. This exercises that concurrent events do not cause a data race in the emitter.
    ///
    /// - Given: Emitter is seeded with events from both the `initialSyncOrchestrator` and `reconcilliationQueue`,
    ///     followed by a finished event from initialSyncOrchestrator
    /// - When:
    ///    - Concurrently receive more events from the `reconcilliationQueue`
    /// - Then:
    ///    - `modelSyncedEvent` received and emitter continues to send mutation events
    ///
    func testConcurrent() throws {
        let modelSyncedReceived = expectation(description: "modelSynced received")
        let mutationEventAppliedReceived = expectation(description: "mutationEventApplied received")
        mutationEventAppliedReceived.assertForOverFulfill = false
        let mutationEventDroppedReceived = expectation(description: "mutationEventDropped received")
        mutationEventDroppedReceived.assertForOverFulfill = false
        let anyPostMetadata = MutationSyncMetadata(modelId: "1",
                                                   modelName: Post.modelName,
                                                   deleted: false,
                                                   lastChangedAt: Int(Date().timeIntervalSince1970),
                                                   version: 1)
        let testPost = Post(id: "1", title: "post1", content: "content", createdAt: .now())
        let anyPost = AnyModel(testPost)
        let anyPostMutationSync = MutationSync<AnyModel>(model: anyPost, syncMetadata: anyPostMetadata)
        let postMutationEvent = try MutationEvent(untypedModel: testPost, mutationType: .create)

        let emitter = ModelSyncedEventEmitter(modelSchema: Post.schema,
                                              initialSyncOrchestrator: initialSyncOrchestrator,
                                              reconciliationQueue: reconciliationQueue)

        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.started(modelName: Post.modelName,
                                                                            syncType: .fullSync))
        DispatchQueue.concurrentPerform(iterations: 1_000) { _ in
            let index = Int.random(in: 1 ... 10)
            if index == 1 {
                reconciliationQueue?.incomingEventSubject.send(.mutationEventApplied(postMutationEvent))
            } else if index == 2 {
                reconciliationQueue?.incomingEventSubject.send(.mutationEventDropped(modelName: Post.modelName))
            } else {
                initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.enqueued(anyPostMutationSync,
                                                                                     modelName: Post.modelName))
            }

        }
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.finished(modelName: Post.modelName))

        var emitterSink: AnyCancellable?
        emitterSink = emitter.publisher.sink { _ in
            XCTFail("Should not have completed")
        } receiveValue: { value in
            switch value {
            case .modelSyncedEvent:
                modelSyncedReceived.fulfill()
            case .mutationEventApplied:
                mutationEventAppliedReceived.fulfill()
            case .mutationEventDropped:
                mutationEventDroppedReceived.fulfill()
            }
        }

        DispatchQueue.concurrentPerform(iterations: 3_000) { _ in
            let index = Int.random(in: 1 ... 2)
            if index == 1 {
                reconciliationQueue?.incomingEventSubject.send(.mutationEventApplied(postMutationEvent))
            } else if index == 2 {
                reconciliationQueue?.incomingEventSubject.send(.mutationEventDropped(modelName: Post.modelName))
            }
            _ = emitter.dispatchedModelSyncedEvent
        }

        waitForExpectations(timeout: 10)
        emitterSink?.cancel()
    }
}
