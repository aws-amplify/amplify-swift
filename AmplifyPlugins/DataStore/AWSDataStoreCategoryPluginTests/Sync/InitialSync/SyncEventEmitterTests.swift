//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStoreCategoryPlugin

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
    ///    - Reconcillation of the models occurred
    /// - Then:
    ///    - One modelSynced event should be received
    ///    - One syncQueriesReady event should be received
    func testModelSyncedAndSyncQueriesReadyWithOneModelRegistered() throws {
        let modelSyncedReceived = expectation(description: "modelSynced received")
        let syncQueriesReadyReceived = expectation(description: "syncQueriesReady received")

        ModelRegistry.register(modelType: Post.self)
        let testPost = Post(id: "1", title: "post1", content: "content", createdAt: .now())
        let anyPost = AnyModel(testPost)
        let anyPostMetadata = MutationSyncMetadata(id: "1",
                                                   deleted: false,
                                                   lastChangedAt: Int(Date().timeIntervalSince1970),
                                                   version: 1)
        let anyPostMutationSync = MutationSync<AnyModel>(model: anyPost, syncMetadata: anyPostMetadata)
        let postMutationEvent = try MutationEvent(untypedModel: testPost, mutationType: .create)

        let expectedModelSyncedEventPayload = ModelSyncedEvent(modelName: "Post",
                                                               isFullSync: true, isDeltaSync: false,
                                                               added: 1, updated: 0, deleted: 0)
        let listener = Amplify.Hub.publisher(for: .dataStore).sink { payload in
            switch payload.eventName {
            case HubPayload.EventName.DataStore.modelSynced:
                guard let modelSyncedEventPayload = payload.data as? ModelSyncedEvent else {
                    XCTFail("Couldn't cast payload data as ModelSyncedEvent")
                    return
                }
                XCTAssertTrue(modelSyncedEventPayload == expectedModelSyncedEventPayload)
                modelSyncedReceived.fulfill()
            case HubPayload.EventName.DataStore.syncQueriesReady:
                syncQueriesReadyReceived.fulfill()
            default:
                break
            }
        }

        reconciliationQueue = MockAWSIncomingEventReconciliationQueue(modelTypes: [Post.self],
                                                                      api: nil,
                                                                      storageAdapter: nil,
                                                                      auth: nil)

        initialSyncOrchestrator = MockAWSInitialSyncOrchestrator(dataStoreConfiguration: .default,
                                                                 api: nil,
                                                                 reconciliationQueue: nil,
                                                                 storageAdapter: nil)

        syncEventEmitter = SyncEventEmitter(initialSyncOrchestrator: initialSyncOrchestrator,
                                            reconciliationQueue: reconciliationQueue)

        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.started(modelType: Post.self, syncType: .fullSync))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.enqueued(anyPostMutationSync))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.finished(modelType: Post.self))

        reconciliationQueue?.incomingEventSubject.send(.mutationEventApplied(postMutationEvent))

        waitForExpectations(timeout: 1)
        syncEventEmitter = nil
        listener.cancel()
    }

    /// - Given: A SyncEventEmitter
    /// - When:
    ///    - Two model are registered
    ///      - SyncType of FullSync on Post Model should be performed
    ///      - SyncType of DeltaSync on Comment Model should be performed
    ///      - No SyncQueries comming back
    ///    - Perform an initial sync
    ///    - Reconcillation of the models occurred
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
            = [ModelSyncedEvent(modelName: "Post",
                                isFullSync: true, isDeltaSync: false,
                                added: 0, updated: 0, deleted: 0),
               ModelSyncedEvent(modelName: "Comment",
                                isFullSync: true, isDeltaSync: false,
                                added: 0, updated: 0, deleted: 0)]
        let listener = Amplify.Hub.publisher(for: .dataStore).sink { payload in
            switch payload.eventName {
            case HubPayload.EventName.DataStore.modelSynced:
                guard let modelSyncedEventPayload = payload.data as? ModelSyncedEvent else {
                    XCTFail("Couldn't cast payload data as ModelSyncedEvent")
                    return
                }
                modelSyncedEventPayloads.append(modelSyncedEventPayload)
                if modelSyncedEventPayloads.count == 2 {
                    XCTAssertEqual(modelSyncedEventPayloads[0], expectedModelSyncedEventPayloads[0])
                    XCTAssertEqual(modelSyncedEventPayloads[1], expectedModelSyncedEventPayloads[1])
                    modelSyncedReceived.fulfill()
                }
            case HubPayload.EventName.DataStore.syncQueriesReady:
                syncQueriesReadyReceived.fulfill()
            default:
                break
            }
        }

        let syncableModelTypes = ModelRegistry.models.filter { $0.schema.isSyncable }

        reconciliationQueue = MockAWSIncomingEventReconciliationQueue(modelTypes: syncableModelTypes,
                                                                      api: nil,
                                                                      storageAdapter: nil,
                                                                      auth: nil)

        initialSyncOrchestrator = MockAWSInitialSyncOrchestrator(dataStoreConfiguration: .default,
                                                                 api: nil,
                                                                 reconciliationQueue: nil,
                                                                 storageAdapter: nil)

        syncEventEmitter = SyncEventEmitter(initialSyncOrchestrator: initialSyncOrchestrator,
                                            reconciliationQueue: reconciliationQueue)

        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.started(modelType: Post.self, syncType: .fullSync))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.finished(modelType: Post.self))

        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.started(modelType: Comment.self, syncType: .fullSync))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.finished(modelType: Comment.self))

        waitForExpectations(timeout: 1)
        syncEventEmitter = nil
        listener.cancel()
    }

    /// - Given: A SyncEventEmitter
    /// - When:
    ///    - Two model are registered
    ///      - SyncType of FullSync, .create of MutationType on Post Model would be performed
    ///      - SyncType of FullSync, .delete of MutationType on Comment Model would be performed
    ///      - One SyncQueries of each Model comming back
    ///    - Perform an initial sync
    ///    - Reconcillation of the models occurred
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
        let anyPostMetadata = MutationSyncMetadata(id: "1",
                                                   deleted: false,
                                                   lastChangedAt: Int(Date().timeIntervalSince1970),
                                                   version: 1)
        let anyPostMutationSync = MutationSync<AnyModel>(model: anyPost, syncMetadata: anyPostMetadata)

        let postMutationEvent = try MutationEvent(untypedModel: testPost, mutationType: .create)

        let testComment = Comment(id: "1", content: "content", createdAt: .now(), post: testPost)
        let anyComment = AnyModel(testComment)
        let anyCommentMetadata = MutationSyncMetadata(id: "1",
                                                      deleted: true,
                                                      lastChangedAt: Int(Date().timeIntervalSince1970),
                                                      version: 2)
        let anyCommentMutationSync = MutationSync<AnyModel>(model: anyComment, syncMetadata: anyCommentMetadata)
        let commentMutationEvent = try MutationEvent(untypedModel: testComment, mutationType: .delete)

        let expectedModelSyncedEventPayloads: [ModelSyncedEvent]
            = [ModelSyncedEvent(modelName: "Post",
                                isFullSync: true, isDeltaSync: false,
                                added: 1, updated: 0, deleted: 0),
               ModelSyncedEvent(modelName: "Comment",
                                isFullSync: true, isDeltaSync: false,
                                added: 0, updated: 0, deleted: 1)]
        var modelSyncedEventPayloads = [ModelSyncedEvent]()
        let listener = Amplify.Hub.publisher(for: .dataStore).sink { payload in
            switch payload.eventName {
            case HubPayload.EventName.DataStore.modelSynced:
                guard let modelSyncedEventPayload = payload.data as? ModelSyncedEvent else {
                    XCTFail("Couldn't cast payload data as ModelSyncedEvent")
                    return
                }
                modelSyncedEventPayloads.append(modelSyncedEventPayload)

                if modelSyncedEventPayloads.count == 2 {
                    XCTAssertTrue(modelSyncedEventPayloads[0] == expectedModelSyncedEventPayloads[0])
                    XCTAssertTrue(modelSyncedEventPayloads[1] == expectedModelSyncedEventPayloads[1])
                    modelSyncedReceived.fulfill()
                }
            case HubPayload.EventName.DataStore.syncQueriesReady:
                syncQueriesReadyReceived.fulfill()
            default:
                break
            }
        }

        let syncableModelTypes = ModelRegistry.models.filter { $0.schema.isSyncable }

        reconciliationQueue = MockAWSIncomingEventReconciliationQueue(modelTypes: syncableModelTypes,
                                                                      api: nil,
                                                                      storageAdapter: nil,
                                                                      auth: nil)

        initialSyncOrchestrator = MockAWSInitialSyncOrchestrator(dataStoreConfiguration: .default,
                                                                 api: nil,
                                                                 reconciliationQueue: nil,
                                                                 storageAdapter: nil)

        syncEventEmitter = SyncEventEmitter(initialSyncOrchestrator: initialSyncOrchestrator,
                                            reconciliationQueue: reconciliationQueue)

        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.started(modelType: Post.self, syncType: .fullSync))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.enqueued(anyPostMutationSync))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.finished(modelType: Post.self))

        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.started(modelType: Comment.self, syncType: .fullSync))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.enqueued(anyCommentMutationSync))
        initialSyncOrchestrator?.initialSyncOrchestratorTopic.send(.finished(modelType: Comment.self))

        reconciliationQueue?.incomingEventSubject.send(.mutationEventApplied(postMutationEvent))
        reconciliationQueue?.incomingEventSubject.send(.mutationEventApplied(commentMutationEvent))

        waitForExpectations(timeout: 1)
        syncEventEmitter = nil
        listener.cancel()
    }
}
