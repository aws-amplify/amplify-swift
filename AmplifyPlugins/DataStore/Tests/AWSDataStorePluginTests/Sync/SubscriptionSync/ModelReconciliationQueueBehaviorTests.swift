//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin
@testable import AWSPluginsCore

class ModelReconciliationQueueBehaviorTests: ReconciliationQueueTestBase {

    /// - Given: A new AWSModelReconciliationQueue
    /// - When:
    ///    - I publish incoming events
    /// - Then:
    ///    - The queue does not process them
    func testBuffersBeforeStart() async throws {
        let eventsNotSaved = expectation(description: "Events not saved")
        eventsNotSaved.isInverted = true
        storageAdapter.responders[.saveUntypedModel] = SaveUntypedModelResponder { _, _ in
            eventsNotSaved.fulfill()
        }

        let queue = await AWSModelReconciliationQueue(modelSchema: MockSynced.schema,
                                                storageAdapter: storageAdapter,
                                                api: apiPlugin,
                                                reconcileAndSaveQueue: reconcileAndSaveQueue,
                                                modelPredicate: modelPredicate,
                                                auth: authPlugin,
                                                authModeStrategy: AWSDefaultAuthModeStrategy(),
                                                incomingSubscriptionEvents: subscriptionEventsPublisher)

        // We know this won't be nil, but we need to keep a reference to the queue in memory for the duration of the
        // test, and since we don't act on it otherwise, Swift warns about queue never being used.
        XCTAssertNotNil(queue)

        for iteration in 1 ... 3 {
            let model = try MockSynced(id: "id-\(iteration)").eraseToAnyModel()
            let syncMetadata = MutationSyncMetadata(modelId: model.id,
                                                    modelName: model.modelName,
                                                    deleted: false,
                                                    lastChangedAt: Date().unixSeconds,
                                                    version: 1)
            let mutationSync = MutationSync(model: model, syncMetadata: syncMetadata)
            subscriptionEventsSubject.send(.mutationEvent(mutationSync))
        }

        wait(for: [eventsNotSaved], timeout: 5.0)
    }

    /// - Given: An AWSModelReconciliationQueue that has been buffering events
    /// - When:
    ///    - I `start()` the queue
    /// - Then:
    ///    - It processes buffered events in order
    func testProcessesBufferedEvents() async throws {
        let event1Saved = expectation(description: "Event 1 saved")
        let event2Saved = expectation(description: "Event 2 saved")
        let event3Saved = expectation(description: "Event 3 saved")
        storageAdapter.responders[.saveUntypedModel] = SaveUntypedModelResponder { model, completion in
            switch model.identifier(schema: MockSynced.schema).stringValue {
            case "id-1":
                event1Saved.fulfill()
            case "id-2":
                event2Saved.fulfill()
            case "id-3":
                event3Saved.fulfill()
            default:
                break
            }

            completion(.success(model))
        }

        let queue = await AWSModelReconciliationQueue(modelSchema: MockSynced.schema,
                                                storageAdapter: storageAdapter,
                                                api: apiPlugin,
                                                reconcileAndSaveQueue: reconcileAndSaveQueue,
                                                modelPredicate: modelPredicate,
                                                auth: authPlugin,
                                                authModeStrategy: AWSDefaultAuthModeStrategy(),
                                                incomingSubscriptionEvents: subscriptionEventsPublisher)

        for iteration in 1 ... 3 {
            let model = try MockSynced(id: "id-\(iteration)").eraseToAnyModel()
            let syncMetadata = MutationSyncMetadata(modelId: model.id,
                                                    modelName: model.modelName,
                                                    deleted: false,
                                                    lastChangedAt: Date().unixSeconds,
                                                    version: 1)
            let mutationSync = MutationSync(model: model, syncMetadata: syncMetadata)
            subscriptionEventsSubject.send(.mutationEvent(mutationSync))
        }

        let eventsSentViaPublisher1 = expectation(description: "id-1 sent via publisher")
        let eventsSentViaPublisher2 = expectation(description: "id-2 sent via publisher")
        let eventsSentViaPublisher3 = expectation(description: "id-3 sent via publisher")
        let queueSink = queue.publisher.sink(receiveCompletion: { _ in
            XCTFail("Not expecting a call to completion")
        }, receiveValue: { event in
            if case let .mutationEvent(mutationEvent) = event {
                switch mutationEvent.modelId {
                case "id-1":
                    eventsSentViaPublisher1.fulfill()
                case "id-2":
                    eventsSentViaPublisher2.fulfill()
                case "id-3":
                    eventsSentViaPublisher3.fulfill()
                default:
                    XCTFail("Not expecting a call to default")
                }
            }
        })

        queue.start()

        await waitForExpectations(timeout: 5.0)
        queueSink.cancel()
    }

    /// - Given: An AWSModelReconciliationQueue that has been buffering events with a selective sync configuration
    /// - When:
    ///    - I `start()` the queue
    /// - Then:
    ///    - It processes buffered events in order, that evaluate true against the predicate
    func testProcessesEventsWithSelectiveSync() async throws {
        let event1Saved = expectation(description: "Event 1 saved")
        let event3Saved = expectation(description: "Event 3 saved")
        storageAdapter.responders[.saveUntypedModel] = SaveUntypedModelResponder { model, completion in
            switch model.identifier(schema: MockSynced.schema).stringValue {
            case "id-1":
                event1Saved.fulfill()
            case "id-2":
                XCTFail("id-2 should not be saved to be saved")
            case "id-3":
                event3Saved.fulfill()
            default:
                break
            }

            completion(.success(model))
        }
        let syncExpression = DataStoreSyncExpression.syncExpression(MockSynced.schema, where: {
            MockSynced.keys.id == "id-1" || MockSynced.keys.id == "id-3"
        })
        let queue = await AWSModelReconciliationQueue(modelSchema: MockSynced.schema,
                                                storageAdapter: storageAdapter,
                                                api: apiPlugin,
                                                reconcileAndSaveQueue: reconcileAndSaveQueue,
                                                modelPredicate: syncExpression.modelPredicate(),
                                                auth: authPlugin,
                                                authModeStrategy: AWSDefaultAuthModeStrategy(),
                                                incomingSubscriptionEvents: subscriptionEventsPublisher)

        for iteration in 1 ... 3 {
            let model = try MockSynced(id: "id-\(iteration)").eraseToAnyModel()
            let syncMetadata = MutationSyncMetadata(modelId: model.id,
                                                    modelName: model.modelName,
                                                    deleted: false,
                                                    lastChangedAt: Date().unixSeconds,
                                                    version: 1)
            let mutationSync = MutationSync(model: model, syncMetadata: syncMetadata)
            subscriptionEventsSubject.send(.mutationEvent(mutationSync))
        }

        let eventsSentViaPublisher1 = expectation(description: "id-1 sent via publisher")
        let eventsSentViaPublisher3 = expectation(description: "id-3 sent via publisher")
        let queueSink = queue.publisher.sink(receiveCompletion: { _ in
            XCTFail("Not expecting a call to completion")
        }, receiveValue: { event in
            if case let .mutationEvent(mutationEvent) = event {
                switch mutationEvent.modelId {
                case "id-1":
                    eventsSentViaPublisher1.fulfill()
                case "id-2":
                    XCTFail("id-2 should not be saved to be saved")
                case "id-3":
                    eventsSentViaPublisher3.fulfill()
                default:
                    XCTFail("Not expecting a call to default")
                }
            }
        })

        queue.start()

        await waitForExpectations(timeout: 5.0)
        queueSink.cancel()
    }

    /// - Given: An AWSModelReconciliationQueue that has been buffering events
    /// - When:
    ///    - I `start()` the queue
    /// - Then:
    ///    - It processes buffered events one at a time
    func testProcessesBufferedEventsSerially() async throws {
        // This test relies on knowledge of the Reconciliation queue's internal behavior: specifically, that it saves
        // an event's metadata as the last step.

        let event1State = AtomicValue(initialValue: EventState.notStarted)
        let event2State = AtomicValue(initialValue: EventState.notStarted)
        let event3State = AtomicValue(initialValue: EventState.notStarted)

        // Return a successful MockSynced save
        storageAdapter.responders[.saveUntypedModel] = SaveUntypedModelResponder { model, completion in
            completion(.success(model))
        }

        // Return a successful MutationSyncMetadata save, and also assert the event states
        let allEventsProcessed = expectation(description: "All events processed")
        storageAdapter.responders[.saveModelCompletion] =
            SaveModelCompletionResponder<MutationSyncMetadata> { mutationSyncMetadata, completion in
                switch mutationSyncMetadata.modelId {
                case "id-1":
                    XCTAssertEqual(event1State.get(), .notStarted)
                    XCTAssertEqual(event2State.get(), .notStarted)
                    XCTAssertEqual(event3State.get(), .notStarted)
                    event1State.set(.finished)
                    event2State.set(.processing)
                case "id-2":
                    XCTAssertEqual(event1State.get(), .finished)
                    XCTAssertEqual(event2State.get(), .processing)
                    XCTAssertEqual(event3State.get(), .notStarted)
                    event2State.set(.finished)
                    event3State.set(.processing)
                case "id-3":
                    XCTAssertEqual(event1State.get(), .finished)
                    XCTAssertEqual(event2State.get(), .finished)
                    XCTAssertEqual(event3State.get(), .processing)
                    event3State.set(.finished)
                    allEventsProcessed.fulfill()
                default:
                    break
                }
                completion(.success(mutationSyncMetadata))
        }

        let queue = await AWSModelReconciliationQueue(modelSchema: MockSynced.schema,
                                                storageAdapter: storageAdapter,
                                                api: apiPlugin,
                                                reconcileAndSaveQueue: reconcileAndSaveQueue,
                                                modelPredicate: modelPredicate,
                                                auth: authPlugin,
                                                authModeStrategy: AWSDefaultAuthModeStrategy(),
                                                incomingSubscriptionEvents: subscriptionEventsPublisher)
        for iteration in 1 ... 3 {
            let model = try MockSynced(id: "id-\(iteration)").eraseToAnyModel()
            let syncMetadata = MutationSyncMetadata(modelId: model.id,
                                                    modelName: model.modelName,
                                                    deleted: false,
                                                    lastChangedAt: Date().unixSeconds,
                                                    version: 1)
            let mutationSync = MutationSync(model: model, syncMetadata: syncMetadata)
            subscriptionEventsSubject.send(.mutationEvent(mutationSync))
        }

        let eventsSentViaPublisher1 = expectation(description: "id-1 sent via publisher")
        let eventsSentViaPublisher2 = expectation(description: "id-2 sent via publisher")
        let eventsSentViaPublisher3 = expectation(description: "id-3 sent via publisher")

        let queueSink = queue.publisher.sink(receiveCompletion: { _ in
            XCTFail("Not expecting a call to completion")
        }, receiveValue: { event in
            if case let .mutationEvent(mutationEvent) = event {
                switch mutationEvent.modelId {
                case "id-1":
                    eventsSentViaPublisher1.fulfill()
                case "id-2":
                    eventsSentViaPublisher2.fulfill()
                case "id-3":
                    eventsSentViaPublisher3.fulfill()
                default:
                    break
                }
            }
        })

        queue.start()

        await waitForExpectations(timeout: 5.0)
        queueSink.cancel()
    }

    /// - Given: A started AWSModelReconciliationQueue with no pending events
    /// - When:
    ///    - I submit a new event
    /// - Then:
    ///    - The new event immediately processes
    func testProcessesNewEvents() async throws {
        // Return a successful MockSynced save
        storageAdapter.responders[.saveUntypedModel] = SaveUntypedModelResponder { model, completion in
            completion(.success(model))
        }

        let event1ShouldBeProcessed = expectation(description: "Event 1 should be processed")
        let event2ShouldBeProcessed = expectation(description: "Event 2 should be processed")
        storageAdapter.responders[.saveModelCompletion] =
            SaveModelCompletionResponder<MutationSyncMetadata> { mutationSyncMetadata, completion in
                switch mutationSyncMetadata.modelId {
                case "id-1":
                    event1ShouldBeProcessed.fulfill()
                case "id-2":
                    event2ShouldBeProcessed.fulfill()
                default:
                    break
                }
                completion(.success(mutationSyncMetadata))
        }

        let queue = await AWSModelReconciliationQueue(modelSchema: MockSynced.schema,
                                                storageAdapter: storageAdapter,
                                                api: apiPlugin,
                                                reconcileAndSaveQueue: reconcileAndSaveQueue,
                                                modelPredicate: modelPredicate,
                                                auth: authPlugin,
                                                authModeStrategy: AWSDefaultAuthModeStrategy(),
                                                incomingSubscriptionEvents: subscriptionEventsPublisher)
        for iteration in 1 ... 2 {
            let model = try MockSynced(id: "id-\(iteration)").eraseToAnyModel()
            let syncMetadata = MutationSyncMetadata(modelId: model.id,
                                                    modelName: model.modelName,
                                                    deleted: false,
                                                    lastChangedAt: Date().unixSeconds,
                                                    version: 1)
            let mutationSync = MutationSync(model: model, syncMetadata: syncMetadata)
            subscriptionEventsSubject.send(.mutationEvent(mutationSync))
        }

        let eventsSentViaPublisher1 = expectation(description: "id-1 sent via publisher")
        let eventsSentViaPublisher2 = expectation(description: "id-2 sent via publisher")
        var queueSink = queue.publisher.sink(receiveCompletion: { _ in
            XCTFail("Not expecting a call to completion")
        }, receiveValue: { event in
            if case let .mutationEvent(mutationEvent) = event {
                switch mutationEvent.modelId {
                case "id-1":
                    eventsSentViaPublisher1.fulfill()
                case "id-2":
                    eventsSentViaPublisher2.fulfill()
                default:
                    XCTFail("Not expecting a call to default")
                }
            }
        })

        queue.start()

        await waitForExpectations(timeout: 1.0)

        let event1ShouldNotBeProcessed = expectation(description: "Event 1 should not be processed")
        event1ShouldNotBeProcessed.isInverted = true
        let event2ShouldNotBeProcessed = expectation(description: "Event 2 should not be processed")
        event2ShouldNotBeProcessed.isInverted = true
        let event3ShouldBeProcessed = expectation(description: "Event 3 should be processed")
        storageAdapter.responders[.saveModelCompletion] =
            SaveModelCompletionResponder<MutationSyncMetadata> { mutationSyncMetadata, completion in
                switch mutationSyncMetadata.modelId {
                case "id-1":
                    event1ShouldNotBeProcessed.fulfill()
                case "id-2":
                    event2ShouldNotBeProcessed.fulfill()
                case "id-3":
                    event3ShouldBeProcessed.fulfill()
                default:
                    break
                }
                completion(.success(mutationSyncMetadata))
        }

        let eventsSentViaPublisher3 = expectation(description: "id-3 sent via publisher")
        queueSink = queue.publisher.sink(receiveCompletion: { _ in
            XCTFail("Not expecting a call to completion")
        }, receiveValue: { event in
            if case let .mutationEvent(mutationEvent) = event {
                if mutationEvent.modelId == "id-3" {
                    eventsSentViaPublisher3.fulfill()
                }
            }
        })

        let model = try MockSynced(id: "id-3").eraseToAnyModel()
        let syncMetadata = MutationSyncMetadata(modelId: model.id,
                                                modelName: model.modelName,
                                                deleted: false,
                                                lastChangedAt: Date().unixSeconds,
                                                version: 1)
        let mutationSync = MutationSync(model: model, syncMetadata: syncMetadata)
        subscriptionEventsSubject.send(.mutationEvent(mutationSync))

        await waitForExpectations(timeout: 1.0)
        queueSink.cancel()
    }

}

extension ModelReconciliationQueueBehaviorTests {
    private func completionSignalWithAppSyncError(_ error: AppSyncErrorType) -> Subscribers.Completion<DataStoreError> {
        let appSyncJSONValue: JSONValue = .string(error.rawValue)
        let graphqlError = GraphQLError.init(message: "",
                                             locations: nil,
                                             path: nil,
                                             extensions: [
                                                "errorType": appSyncJSONValue])
        let graphqlResponseError = GraphQLResponseError<MutationSync<AnyModel>>.error([graphqlError])
        let apiError = APIError.operationError("error message", "recovery message", graphqlResponseError)
        let dataStoreError = DataStoreError.api(apiError, nil)
        return .failure(dataStoreError)
    }

    func testProcessingUnauthorizedError() async {
        let eventSentViaPublisher = expectation(description: "Sent via publisher")
        let queue = await AWSModelReconciliationQueue(modelSchema: MockSynced.schema,
                                                storageAdapter: storageAdapter,
                                                api: apiPlugin,
                                                reconcileAndSaveQueue: reconcileAndSaveQueue,
                                                modelPredicate: modelPredicate,
                                                auth: authPlugin,
                                                authModeStrategy: AWSDefaultAuthModeStrategy(),
                                                incomingSubscriptionEvents: subscriptionEventsPublisher)
        let completion = completionSignalWithAppSyncError(AppSyncErrorType.unauthorized)

        let queueSink = queue.publisher.sink(receiveCompletion: { value in
            XCTFail("Not expecting a call to completion, received \(value)")
        }, receiveValue: { _ in
            eventSentViaPublisher.fulfill()
        })

        subscriptionEventsSubject.send(completion: completion)
        wait(for: [eventSentViaPublisher], timeout: 1.0)
        queueSink.cancel()
    }

    func testProcessingOperationDisabledError() async {
        let eventSentViaPublisher = expectation(description: "Sent via publisher")
        let queue = await AWSModelReconciliationQueue(modelSchema: MockSynced.schema,
                                                storageAdapter: storageAdapter,
                                                api: apiPlugin,
                                                reconcileAndSaveQueue: reconcileAndSaveQueue,
                                                modelPredicate: modelPredicate,
                                                auth: authPlugin,
                                                authModeStrategy: AWSDefaultAuthModeStrategy(),
                                                incomingSubscriptionEvents: subscriptionEventsPublisher)
        let completion = completionSignalWithAppSyncError(AppSyncErrorType.operationDisabled)

        let queueSink = queue.publisher.sink(receiveCompletion: { value in
            XCTFail("Not expecting a call to completion, received \(value)")
        }, receiveValue: { _ in
            eventSentViaPublisher.fulfill()
        })

        subscriptionEventsSubject.send(completion: completion)
        wait(for: [eventSentViaPublisher], timeout: 1.0)
        queueSink.cancel()
    }

    func testProcessingUnhandledErrors() async {
        let eventSentViaPublisher = expectation(description: "Sent via publisher")
        let queue = await AWSModelReconciliationQueue(modelSchema: MockSynced.schema,
                                                storageAdapter: storageAdapter,
                                                api: apiPlugin,
                                                reconcileAndSaveQueue: reconcileAndSaveQueue,
                                                modelPredicate: modelPredicate,
                                                auth: authPlugin,
                                                authModeStrategy: AWSDefaultAuthModeStrategy(),
                                                incomingSubscriptionEvents: subscriptionEventsPublisher)
        let completion = completionSignalWithAppSyncError(AppSyncErrorType.conflictUnhandled)

        let queueSink = queue.publisher.sink(receiveCompletion: { _ in
            eventSentViaPublisher.fulfill()
        }, receiveValue: { value in
            XCTFail("Not expecting a successful call, received \(value)")
        })

        subscriptionEventsSubject.send(completion: completion)
        wait(for: [eventSentViaPublisher], timeout: 1.0)
        queueSink.cancel()
    }
}

enum EventState {
    case notStarted
    case processing
    case finished
}
