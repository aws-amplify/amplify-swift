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

    func testInitialState() async {
        let expect = asyncExpectation(description: "state initialized")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.initialized)
            Task { await expect.fulfill() }
        }

        mutationQueue = OutgoingMutationQueue(stateMachine,
                                              storageAdapter: storageAdapter,
                                              dataStoreConfiguration: .default,
                                              authModeStrategy: AWSDefaultAuthModeStrategy())
        
        await waitForExpectations([expect], timeout: 1)

        XCTAssertEqual(stateMachine.state, OutgoingMutationQueue.State.notInitialized)
    }

    func testStartingState() async {
        let expect = asyncExpectation(description: "state receivedSubscription")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.receivedSubscription)
            Task { await expect.fulfill() }
        }

        stateMachine.state = .starting(apiBehavior, publisher, reconciliationQueue)
        await waitForExpectations([expect], timeout: 1)
    }

    func testRequestingEvent_subscriptionSetup() async throws {
        let model = MockSynced(id: "id-1")
        let anyModel = try model.eraseToAnyModel()
        let remoteSyncMetadata = MutationSyncMetadata(modelId: model.id,
                                                      modelName: MockSynced.modelName,
                                                      deleted: false,
                                                      lastChangedAt: Date().unixSeconds,
                                                      version: 2)
        let remoteMutationSync = MutationSync(model: anyModel, syncMetadata: remoteSyncMetadata)
        
        let receivedSubscription = asyncExpectation(description: "state machine received receivedSubscription")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.receivedSubscription)
            Task { await receivedSubscription.fulfill() }
        }
        stateMachine.state = .starting(apiBehavior, publisher, reconciliationQueue)
        await waitForExpectations([receivedSubscription], timeout: 1.0)

        let json = "{\"id\":\"1234\",\"title\":\"t\",\"content\":\"c\",\"createdAt\":\"2020-09-03T22:55:13.424Z\"}"
        let futureResult = MutationEvent(modelId: "1",
                                         modelName: "Post",
                                         json: json,
                                         mutationType: MutationEvent.MutationType.create)
        eventSource.pushMutationEvent(futureResult: .success(futureResult))

        let enqueueEvent = asyncExpectation(description: "state requestingEvent, enqueueEvent")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.enqueuedEvent)
            Task { await enqueueEvent.fulfill() }
        }

        let apiMutationReceived = asyncExpectation(description: "API call for mutate received")
        let responder = MutateRequestResponder<MutationSync<AnyModel>> { _ in
            Task { await apiMutationReceived.fulfill() }
            return .success(.success(remoteMutationSync))
        }
        apiBehavior.responders[.mutateRequestResponse] = responder

        stateMachine.state = .requestingEvent

        await waitForExpectations([enqueueEvent, apiMutationReceived], timeout: 1)

        let processEvent = asyncExpectation(description: "state requestingEvent, processedEvent")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.processedEvent)
            Task { await processEvent.fulfill() }
        }

        await waitForExpectations([processEvent], timeout: 1)
    }

    func testRequestingEvent_nosubscription() async {
        let expect = asyncExpectation(description: "state requestingEvent, no subscription")
        stateMachine.pushExpectActionCriteria { action in
            let error = DataStoreError.unknown("_", "", nil)
            XCTAssertEqual(action, OutgoingMutationQueue.Action.errored(error))
            Task { await expect.fulfill() }
        }

        stateMachine.state = .requestingEvent
        await waitForExpectations([expect], timeout: 1)
    }

    func testReceivedStartActionWhileExpectingEventProcessedAction() async throws {
        let model = MockSynced(id: "id-1")
        let anyModel = try model.eraseToAnyModel()
        let remoteSyncMetadata = MutationSyncMetadata(modelId: model.id,
                                                      modelName: MockSynced.modelName,
                                                      deleted: false,
                                                      lastChangedAt: Date().unixSeconds,
                                                      version: 2)
        let remoteMutationSync = MutationSync(model: anyModel, syncMetadata: remoteSyncMetadata)
        
        // Ensure subscription is setup
        let receivedSubscription = asyncExpectation(description: "receivedSubscription")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.receivedSubscription)
            Task { await receivedSubscription.fulfill() }
        }
        stateMachine.state = .starting(apiBehavior, publisher, reconciliationQueue)
        await waitForExpectations([receivedSubscription], timeout: 0.1)

        // Mock incoming mutation event
        let post = Post(title: "title",
                        content: "content",
                        createdAt: .now())
        let futureResult = try MutationEvent(model: post,
                                             modelSchema: post.schema,
                                             mutationType: .create)
        eventSource.pushMutationEvent(futureResult: .success(futureResult))

        let enqueueEvent = asyncExpectation(description: "state requestingEvent, enqueueEvent")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.enqueuedEvent)
            Task { await enqueueEvent.fulfill() }
        }
        let mutateAPICallExpecation = asyncExpectation(description: "Call to api category for mutate")
        let responder = MutateRequestResponder<MutationSync<AnyModel>> { _ in
            Task { await mutateAPICallExpecation.fulfill() }
            return .success(.success(remoteMutationSync))
        }
        apiBehavior.responders[.mutateRequestResponse] = responder

        stateMachine.state = .requestingEvent
        await waitForExpectations([enqueueEvent, mutateAPICallExpecation], timeout: 1)

        // While we are expecting the mutationEvent to be processed by making an API call,
        // stop the mutation queue. Note that we are not testing that the operation
        // actually gets cancelled, the purpose of this test is to test the state transition
        // when we call startSyncingToCloud()
        let mutationQueueStopped = asyncExpectation(description: "mutationQueueStopped")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.receivedStop {})
            Task { await mutationQueueStopped.fulfill() }
        }
        mutationQueue.stopSyncingToCloud { }
        await waitForExpectations([mutationQueueStopped], timeout: 0.1)

        // Re-enable syncing
        let startReceivedAgain = asyncExpectation(description: "Start received again")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.receivedStart(self.apiBehavior,
                                                                              self.publisher,
                                                                              self.reconciliationQueue))
            Task { await startReceivedAgain.fulfill() }
        }

        mutationQueue.startSyncingToCloud(api: apiBehavior,
                                          mutationEventPublisher: publisher,
                                          reconciliationQueue: reconciliationQueue)

        await waitForExpectations([startReceivedAgain], timeout: 1)

        // After - enabling, mock the callback from API to be completed
        let processEvent = asyncExpectation(description: "state requestingEvent, processedEvent")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.processedEvent)
            Task { await processEvent.fulfill() }
        }

        await waitForExpectations([processEvent], timeout: 1)
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
