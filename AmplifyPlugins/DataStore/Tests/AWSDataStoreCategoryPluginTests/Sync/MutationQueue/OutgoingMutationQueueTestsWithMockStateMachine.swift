//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStorePlugin

class OutgoingMutationQueueMockStateTest: XCTestCase {
    var mutationQueue: OutgoingMutationQueue!
    var stateMachine: MockStateMachine<OutgoingMutationQueue.State, OutgoingMutationQueue.Action>!
    var publisher: AWSMutationEventPublisher!
    var reconciliationQueue: IncomingEventReconciliationQueue!
    var apiBehavior: MockAPICategoryPlugin!
    var storageAdapter: StorageEngineAdapter!
    var eventSource: MockMutationEventSource!
    override func setUp() async throws {
        do {
            try await setUpWithAPI()
        } catch {
            XCTFail(String(describing: "Unable to setup API category for unit tests"))
        }
        ModelRegistry.register(modelType: Post.self)
        stateMachine = MockStateMachine(initialState: .notInitialized,
                                        resolver: OutgoingMutationQueue.Resolver.resolve(currentState:action:))
        storageAdapter = MockSQLiteStorageEngineAdapter()
        mutationQueue = OutgoingMutationQueue(stateMachine,
                                              storageAdapter: storageAdapter,
                                              dataStoreConfiguration: .default,
                                              authModeStrategy: AWSDefaultAuthModeStrategy())
        eventSource = MockMutationEventSource()
        publisher = AWSMutationEventPublisher(eventSource: eventSource)
        apiBehavior = MockAPICategoryPlugin()
        reconciliationQueue = MockReconciliationQueue()
    }

    func testInitialState() {
        let expect = expectation(description: "state initialized")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.initialized)
            expect.fulfill()
        }

        mutationQueue = OutgoingMutationQueue(stateMachine,
                                              storageAdapter: storageAdapter,
                                              dataStoreConfiguration: .default,
                                              authModeStrategy: AWSDefaultAuthModeStrategy())
        waitForExpectations(timeout: 1)

        XCTAssertEqual(stateMachine.state, OutgoingMutationQueue.State.notInitialized)
    }

    func testStartingState() {
        let expect = expectation(description: "state receivedSubscription")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.receivedSubscription)
            expect.fulfill()
        }

        stateMachine.state = .starting(apiBehavior, publisher, reconciliationQueue)
        waitForExpectations(timeout: 1)
    }

    func testRequestingEvent_subscriptionSetup() throws {
        let semaphore = DispatchSemaphore(value: 0)
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.receivedSubscription)
            semaphore.signal()
        }
        stateMachine.state = .starting(apiBehavior, publisher, reconciliationQueue)
        semaphore.wait()

        let json = "{\"id\":\"1234\",\"title\":\"t\",\"content\":\"c\",\"createdAt\":\"2020-09-03T22:55:13.424Z\"}"
        let futureResult = MutationEvent(modelId: "1",
                                         modelName: "Post",
                                         json: json,
                                         mutationType: MutationEvent.MutationType.create)
        eventSource.pushMutationEvent(futureResult: .success(futureResult))

        let enqueueEvent = expectation(description: "state requestingEvent, enqueueEvent")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.enqueuedEvent)
            enqueueEvent.fulfill()
        }

        let apiMutationReceived = expectation(description: "API call for mutate received")
        var listenerFromRequest: GraphQLOperation<MutationSync<AnyModel>>.ResultListener!
        let responder = MutateRequestListenerResponder<MutationSync<AnyModel>> { _, eventListener in
            apiMutationReceived.fulfill()
            listenerFromRequest = eventListener
            return nil
        }
        apiBehavior.responders[.mutateRequestListener] = responder

        stateMachine.state = .requestingEvent

        wait(for: [enqueueEvent, apiMutationReceived], timeout: 1)

        let processEvent = expectation(description: "state requestingEvent, processedEvent")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.processedEvent)
            processEvent.fulfill()
        }

        let model = MockSynced(id: "id-1")
        let anyModel = try model.eraseToAnyModel()
        let remoteSyncMetadata = MutationSyncMetadata(modelId: model.id,
                                                      modelName: MockSynced.modelName,
                                                      deleted: false,
                                                      lastChangedAt: Date().unixSeconds,
                                                      version: 2)
        let remoteMutationSync = MutationSync(model: anyModel, syncMetadata: remoteSyncMetadata)
        listenerFromRequest(.success(.success(remoteMutationSync)))

        wait(for: [processEvent], timeout: 1)
    }

    func testRequestingEvent_nosubscription() {
        let expect = expectation(description: "state requestingEvent, no subscription")
        stateMachine.pushExpectActionCriteria { action in
            let error = DataStoreError.unknown("_", "", nil)
            XCTAssertEqual(action, OutgoingMutationQueue.Action.errored(error))
            expect.fulfill()
        }

        stateMachine.state = .requestingEvent
        waitForExpectations(timeout: 1)
    }

    func testReceivedStartActionWhileExpectingEventProcessedAction() throws {
        // Ensure subscription is setup
        let receivedSubscription = expectation(description: "receivedSubscription")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.receivedSubscription)
            receivedSubscription.fulfill()
        }
        stateMachine.state = .starting(apiBehavior, publisher, reconciliationQueue)
        wait(for: [receivedSubscription], timeout: 0.1)

        // Mock incoming mutation event
        let post = Post(title: "title",
                        content: "content",
                        createdAt: .now())
        let futureResult = try MutationEvent(model: post,
                                             modelSchema: post.schema,
                                             mutationType: .create)
        eventSource.pushMutationEvent(futureResult: .success(futureResult))

        let enqueueEvent = expectation(description: "state requestingEvent, enqueueEvent")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.enqueuedEvent)
            enqueueEvent.fulfill()
        }
        let mutateAPICallExpecation = expectation(description: "Call to api category for mutate")
        var listenerFromRequest: GraphQLOperation<MutationSync<AnyModel>>.ResultListener!
        let responder = MutateRequestListenerResponder<MutationSync<AnyModel>> { _, eventListener in
            mutateAPICallExpecation.fulfill()
            listenerFromRequest = eventListener
            return nil
        }
        apiBehavior.responders[.mutateRequestListener] = responder

        stateMachine.state = .requestingEvent
        wait(for: [enqueueEvent, mutateAPICallExpecation], timeout: 0.1)

        // While we are expecting the mutationEvent to be processed by making an API call,
        // stop the mutation queue. Note that we are not testing that the operation
        // actually gets cancelled, the purpose of this test is to test the state transition
        // when we call startSyncingToCloud()
        let mutationQueueStopped = expectation(description: "mutationQueueStopped")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.receivedStop {})
            mutationQueueStopped.fulfill()
        }
        mutationQueue.stopSyncingToCloud { }
        wait(for: [mutationQueueStopped], timeout: 0.1)

        // Re-enable syncing
        let startReceivedAgain = expectation(description: "Start received again")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.receivedStart(self.apiBehavior,
                                                                              self.publisher,
                                                                              self.reconciliationQueue))
            startReceivedAgain.fulfill()
        }

        mutationQueue.startSyncingToCloud(api: apiBehavior,
                                          mutationEventPublisher: publisher,
                                          reconciliationQueue: reconciliationQueue)

        wait(for: [startReceivedAgain], timeout: 1)

        // After - enabling, mock the callback from API to be completed
        let processEvent = expectation(description: "state requestingEvent, processedEvent")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.processedEvent)
            processEvent.fulfill()
        }

        let model = MockSynced(id: "id-1")
        let anyModel = try model.eraseToAnyModel()
        let remoteSyncMetadata = MutationSyncMetadata(modelId: model.id,
                                                      modelName: MockSynced.modelName,
                                                      deleted: false,
                                                      lastChangedAt: Date().unixSeconds,
                                                      version: 2)
        let remoteMutationSync = MutationSync(model: anyModel, syncMetadata: remoteSyncMetadata)
        listenerFromRequest(.success(.success(remoteMutationSync)))

        wait(for: [processEvent], timeout: 1)
    }
}

extension OutgoingMutationQueue.State: Equatable {
    public static func == (lhs: OutgoingMutationQueue.State, rhs: OutgoingMutationQueue.State) -> Bool {
        switch (lhs, rhs) {
        case (.notInitialized, notInitialized):
            return true
        case (.stopped, .stopped):
            return true
        case (.starting, .starting):
            return true
        case (.requestingEvent, .requestingEvent):
            return true
        case (.waitingForEventToProcess, .waitingForEventToProcess):
            return true
        case (.inError, .inError):
            return true
        default:
            return false
        }
    }
}

extension OutgoingMutationQueue.Action: Equatable {
    public static func == (lhs: OutgoingMutationQueue.Action, rhs: OutgoingMutationQueue.Action) -> Bool {
        switch (lhs, rhs) {
        case (.initialized, .initialized):
            return true
        case (.receivedStart, .receivedStart):
            return true
        case (.receivedSubscription, .receivedSubscription):
            return true
        case (.enqueuedEvent, .enqueuedEvent):
            return true
        case (.processedEvent, .processedEvent):
            return true
        case (.receivedStop, .receivedStop):
            return true
        case (.errored, .errored):
            return true
        default:
            return false
        }
    }
}

class MockMutationEventSource: MutationEventSource {
    var resultQueue = [DataStoreResult<MutationEvent>]()

    func pushMutationEvent(futureResult: DataStoreResult<MutationEvent>) {
        resultQueue.append(futureResult)
    }

    func getNextMutationEvent(completion: @escaping DataStoreCallback<MutationEvent>) {
        guard let result = resultQueue.first else {
            XCTFail("No result queued up, use pushMutationEvent() to queue up results")
            return
        }
        resultQueue.removeFirst()
        completion(result)
    }
}

extension OutgoingMutationQueueMockStateTest {

    private func setUpCore() async throws -> AmplifyConfiguration {
        await Amplify.reset()

        let dataStorePublisher = DataStorePublisher()
        let dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                                 storageEngineBehaviorFactory: MockStorageEngineBehavior.mockStorageEngineBehaviorFactory,
                                                 dataStorePublisher: dataStorePublisher,
                                                 validAPIPluginKey: "MockAPICategoryPlugin",
                                                 validAuthPluginKey: "MockAuthCategoryPlugin")
        try Amplify.add(plugin: dataStorePlugin)
        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStorePlugin": true
        ])
        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)
        return amplifyConfig
    }

    private func setUpAPICategory(config: AmplifyConfiguration) throws -> AmplifyConfiguration {
        let apiPlugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: apiPlugin)

        let apiConfig = APICategoryConfiguration(plugins: [
            "MockAPICategoryPlugin": true
        ])
        let amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: config.dataStore)
        return amplifyConfig
    }

    private func setUpWithAPI() async throws {
        let configWithoutAPI = try await setUpCore()
        let configWithAPI = try setUpAPICategory(config: configWithoutAPI)
        try Amplify.configure(configWithAPI)
    }

}
