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

class SyncEventEmitterTests: XCTestCase {
    var initialSyncOrchestrator: MockAWSInitialSyncOrchestrator?
    var reconciliationQueue: MockAWSIncomingEventReconciliationQueue?
    var syncEventEmitter: SyncEventEmitter?

    override func setUp() {
        super.setUp()

        ModelRegistry.reset()
        MockModelReconciliationQueue.reset()
        MockAWSInitialSyncOrchestrator.reset()
    }

    /// - Given: A SyncEventEmitter
    /// - When:
    ///    - One model is registered
    ///    - Perform an initial sync
    ///    - Reconciliation of the models occurred
    /// - Then:
    ///    - One modelSynced event should be received
    ///    - One syncQueriesReady event should be received
    func testModelSyncedAndSyncQueriesReadyWithOneModelRegistered() throws {
        let modelSyncedReceived = expectation(description: "modelSynced received")
        let syncQueriesReadyReceived = expectation(description: "syncQueriesReady received")

        ModelRegistry.register(modelType: Post.self)
        let testPost = Post(id: "1", title: "post1", content: "content", createdAt: .now())
        let anyPost = AnyModel(testPost)
        let anyPostMetadata = MutationSyncMetadata(modelId: "1",
                                                   modelName: Post.modelName,
                                                   deleted: false,
                                                   lastChangedAt: Int(Date().timeIntervalSince1970),
                                                   version: 1)
        let anyPostMutationSync = MutationSync<AnyModel>(model: anyPost, syncMetadata: anyPostMetadata)
        let postMutationEvent = try MutationEvent(untypedModel: testPost, mutationType: .create)

        reconciliationQueue = MockAWSIncomingEventReconciliationQueue(modelSchemas: [Post.schema],
                                                                      api: nil,
                                                                      storageAdapter: nil,
                                                                      syncExpressions: [],
                                                                      auth: nil)

        initialSyncOrchestrator = MockAWSInitialSyncOrchestrator(dataStoreConfiguration: .default,
                                                                 api: nil,
                                                                 reconciliationQueue: nil,
                                                                 storageAdapter: nil)

        syncEventEmitter = SyncEventEmitter(initialSyncOrchestrator: initialSyncOrchestrator,
                                            reconciliationQueue: reconciliationQueue)
        var syncEventEmitterSink: AnyCancellable?
        syncEventEmitterSink = syncEventEmitter?.publisher.sink(receiveCompletion: { completion in
            XCTFail("Should not have completed: \(completion)")
        }, receiveValue: { event in
            switch event {
            case .mutationEventApplied:
                break
            case .mutationEventDropped:
                break
            case .modelSyncedEvent(let modelSyncedEvent):
                let expectedModelSyncedEventPayload = ModelSyncedEvent(modelName: "Post",
                                                                       isFullSync: true, isDeltaSync: false,
                                                                       added: 1, updated: 0, deleted: 0)
                XCTAssertTrue(modelSyncedEvent == expectedModelSyncedEventPayload)
                modelSyncedReceived.fulfill()
            case .syncQueriesReadyEvent:
                syncQueriesReadyReceived.fulfill()
            }
        })

        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.started(modelName: Post.modelName,
                                                                            syncType: .fullSync))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.enqueued(anyPostMutationSync,
                                                                             modelName: Post.modelName))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.finished(modelName: Post.modelName))

        reconciliationQueue?.incomingEventSubject.send(.mutationEventApplied(postMutationEvent))

        waitForExpectations(timeout: 1)
        syncEventEmitter = nil
        syncEventEmitterSink?.cancel()
    }

    /// - Given: A SyncEventEmitter
    /// - When:
    ///    - Two model are registered
    ///      - SyncType of FullSync on Post Model should be performed
    ///      - SyncType of DeltaSync on Comment Model should be performed
    ///      - No SyncQueries comming back
    ///    - Perform an initial sync
    ///    - Reconciliation of the models occurred
    /// - Then:
    ///    - Two modelSynced event should be received
    ///    - One syncQueriesReady event should be received
    func testModelSyncedAndSyncQueriesReadyWithTwoModelsRegisteredAndNoSyncQueriesComingBack() throws {
        let modelSyncedReceived = expectation(description: "modelSynced received")
        let syncQueriesReadyReceived = expectation(description: "syncQueriesReady received")

        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)

        var modelSyncedEventPayloads = [ModelSyncedEvent]()
        let expectedModelSyncedEventPayloads: [ModelSyncedEvent]
            = [ModelSyncedEvent(modelName: "Comment",
                                isFullSync: true, isDeltaSync: false,
                                added: 0, updated: 0, deleted: 0),
               ModelSyncedEvent(modelName: "Post",
                                isFullSync: true, isDeltaSync: false,
                                added: 0, updated: 0, deleted: 0)]

        let syncableModelSchemas = ModelRegistry.modelSchemas.filter { $0.isSyncable }

        reconciliationQueue = MockAWSIncomingEventReconciliationQueue(modelSchemas: syncableModelSchemas,
                                                                      api: nil,
                                                                      storageAdapter: nil,
                                                                      syncExpressions: [],
                                                                      auth: nil)

        initialSyncOrchestrator = MockAWSInitialSyncOrchestrator(dataStoreConfiguration: .default,
                                                                 api: nil,
                                                                 reconciliationQueue: nil,
                                                                 storageAdapter: nil)

        syncEventEmitter = SyncEventEmitter(initialSyncOrchestrator: initialSyncOrchestrator,
                                            reconciliationQueue: reconciliationQueue)

        var syncEventEmitterSink: AnyCancellable?
        syncEventEmitterSink = syncEventEmitter?.publisher.sink(receiveCompletion: { completion in
            XCTFail("Should not have completed: \(completion)")
        }, receiveValue: { event in
            switch event {
            case .mutationEventApplied:
                break
            case .mutationEventDropped:
                break
            case .modelSyncedEvent(let modelSyncedEvent):
                modelSyncedEventPayloads.append(modelSyncedEvent)
                if modelSyncedEventPayloads.count == 2 {
                    modelSyncedEventPayloads.sort {
                        $0.modelName < $1.modelName
                    }
                    XCTAssertEqual(modelSyncedEventPayloads[0], expectedModelSyncedEventPayloads[0])
                    XCTAssertEqual(modelSyncedEventPayloads[1], expectedModelSyncedEventPayloads[1])
                    modelSyncedReceived.fulfill()
                }
            case .syncQueriesReadyEvent:
                syncQueriesReadyReceived.fulfill()
            }
        })

        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.started(modelName: Post.modelName, syncType: .fullSync))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.finished(modelName: Post.modelName))

        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.started(modelName: Comment.modelName, syncType: .fullSync))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.finished(modelName: Comment.modelName))

        waitForExpectations(timeout: 1)
        syncEventEmitter = nil
        syncEventEmitterSink?.cancel()
    }

    /// - Given: A SyncEventEmitter
    /// - When:
    ///    - Two model are registered
    ///      - SyncType of FullSync, .create of MutationType on Post Model would be performed
    ///      - SyncType of FullSync, .delete of MutationType on Comment Model would be performed
    ///      - One SyncQueries of each Model comming back
    ///    - Perform an initial sync
    ///    - Reconciliation of the models occurred
    /// - Then:
    ///    - Two modelSynced event should be received
    ///    - One syncQueriesReady event should be received
    func testModelSyncedAndSyncQueriesReadyWithTwoModelsRegisteredAndSyncQueriesComingBack() throws {
        let modelSyncedReceived = expectation(description: "modelSynced received")
        let syncQueriesReadyReceived = expectation(description: "syncQueriesReady received")

        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)
        let testPost = Post(id: "1", title: "post1", content: "content", createdAt: .now())
        let anyPost = AnyModel(testPost)
        let anyPostMetadata = MutationSyncMetadata(modelId: "1",
                                                   modelName: Post.modelName,
                                                   deleted: false,
                                                   lastChangedAt: Int(Date().timeIntervalSince1970),
                                                   version: 1)
        let anyPostMutationSync = MutationSync<AnyModel>(model: anyPost, syncMetadata: anyPostMetadata)

        let postMutationEvent = try MutationEvent(untypedModel: testPost, mutationType: .create)

        let testComment = Comment(id: "1", content: "content", createdAt: .now(), post: testPost)
        let anyComment = AnyModel(testComment)
        let anyCommentMetadata = MutationSyncMetadata(modelId: "1",
                                                      modelName: Comment.modelName,
                                                      deleted: true,
                                                      lastChangedAt: Int(Date().timeIntervalSince1970),
                                                      version: 2)
        let anyCommentMutationSync = MutationSync<AnyModel>(model: anyComment, syncMetadata: anyCommentMetadata)
        let commentMutationEvent = try MutationEvent(untypedModel: testComment, mutationType: .delete)

        let expectedModelSyncedEventPayloads: [ModelSyncedEvent]
            = [ModelSyncedEvent(modelName: "Comment",
                                isFullSync: true, isDeltaSync: false,
                                added: 0, updated: 0, deleted: 1),
               ModelSyncedEvent(modelName: "Post",
                                isFullSync: true, isDeltaSync: false,
                                added: 1, updated: 0, deleted: 0)]
        var modelSyncedEventPayloads = [ModelSyncedEvent]()

        let syncableModelSchemas = ModelRegistry.modelSchemas.filter { $0.isSyncable }

        reconciliationQueue = MockAWSIncomingEventReconciliationQueue(modelSchemas: syncableModelSchemas,
                                                                      api: nil,
                                                                      storageAdapter: nil,
                                                                      syncExpressions: [],
                                                                      auth: nil)

        initialSyncOrchestrator = MockAWSInitialSyncOrchestrator(dataStoreConfiguration: .default,
                                                                 api: nil,
                                                                 reconciliationQueue: nil,
                                                                 storageAdapter: nil)

        syncEventEmitter = SyncEventEmitter(initialSyncOrchestrator: initialSyncOrchestrator,
                                            reconciliationQueue: reconciliationQueue)

        var syncEventEmitterSink: AnyCancellable?
        syncEventEmitterSink = syncEventEmitter?.publisher.sink(receiveCompletion: { completion in
            XCTFail("Should not have completed: \(completion)")
        }, receiveValue: { event in
            switch event {
            case .mutationEventApplied:
                break
            case .mutationEventDropped:
                break
            case .modelSyncedEvent(let modelSyncedEvent):
                modelSyncedEventPayloads.append(modelSyncedEvent)

                if modelSyncedEventPayloads.count == 2 {
                    modelSyncedEventPayloads.sort {
                        $0.modelName < $1.modelName
                    }
                    XCTAssertTrue(modelSyncedEventPayloads[0] == expectedModelSyncedEventPayloads[0])
                    XCTAssertTrue(modelSyncedEventPayloads[1] == expectedModelSyncedEventPayloads[1])
                    modelSyncedReceived.fulfill()
                }
            case .syncQueriesReadyEvent:
                syncQueriesReadyReceived.fulfill()
            }
        })

        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.started(modelName: Post.modelName,
                                                                            syncType: .fullSync))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.enqueued(anyPostMutationSync,
                                                                             modelName: Post.modelName))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.finished(modelName: Post.modelName))

        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.started(modelName: Comment.modelName,
                                                                            syncType: .fullSync))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.enqueued(anyCommentMutationSync,
                                                                             modelName: Comment.modelName))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.finished(modelName: Comment.modelName))

        reconciliationQueue?.incomingEventSubject.send(.mutationEventApplied(postMutationEvent))
        reconciliationQueue?.incomingEventSubject.send(.mutationEventApplied(commentMutationEvent))

        waitForExpectations(timeout: 1)
        syncEventEmitter = nil
        syncEventEmitterSink?.cancel()
    }
}
