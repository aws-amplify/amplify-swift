//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStoreCategoryPlugin

class OutgoingMutationQueueMockStateTest: XCTestCase {
    var mutationQueue: OutgoingMutationQueue!
    var stateMachine: MockStateMachine<OutgoingMutationQueue.State, OutgoingMutationQueue.Action>!
    var publisher: AWSMutationEventPublisher!
    var apiBehavior: MockAPICategoryPlugin!
    var storageAdapter: StorageEngineAdapter!
    var eventSource: MockMutationEventSource!
    override func setUp() {
        do {
            try setUpWithAPI()
        } catch {
            XCTFail(String(describing: "Unable to setup API category for unit tests"))
        }
        ModelRegistry.register(modelType: Post.self)
        stateMachine = MockStateMachine(initialState: .notInitialized,
                                        resolver: OutgoingMutationQueue.Resolver.resolve(currentState:action:))
        storageAdapter = MockSQLiteStorageEngineAdapter()
        mutationQueue = OutgoingMutationQueue(stateMachine,
                                              storageAdapter: storageAdapter,
                                              dataStoreConfiguration: .default)
        eventSource = MockMutationEventSource()
        publisher = AWSMutationEventPublisher(eventSource: eventSource)
        apiBehavior = MockAPICategoryPlugin()
    }

    func testInitialState() {
        let expect = expectation(description: "state initialized")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.initialized)
            expect.fulfill()
        }

        mutationQueue = OutgoingMutationQueue(stateMachine,
                                              storageAdapter: storageAdapter,
                                              dataStoreConfiguration: .default)
        waitForExpectations(timeout: 1)

        XCTAssertEqual(stateMachine.state, OutgoingMutationQueue.State.notInitialized)
    }

    func testStartingState() {
        let expect = expectation(description: "state receivedSubscription")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.receivedSubscription)
            expect.fulfill()
        }

        stateMachine.state = .starting(apiBehavior, publisher)
        waitForExpectations(timeout: 1)
    }

    func testRequestingEvent_subscriptionSetup() throws {
        let semaphore = DispatchSemaphore(value: 0)
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.receivedSubscription)
            semaphore.signal()
        }
        stateMachine.state = .starting(apiBehavior, publisher)
        semaphore.wait()

        let json = "{\"id\":\"1234\",\"title\":\"t\",\"content\":\"c\",\"createdAt\":\"2020-09-03T22:55:13.424Z\"}"
        let futureResult = MutationEvent(modelId: "1",
                                         modelName: "Post",
                                         json: json,
                                         mutationType: MutationEvent.MutationType.create)
        eventSource.pushMutationEvent(futureResult: .success(futureResult))

        let enqueueEvent = expectation(description: "state requestingEvent, enqueueEvent")
        let processEvent = expectation(description: "state requestingEvent, processedEvent")

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

        wait(for: [enqueueEvent, mutateAPICallExpecation], timeout: 1)

        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.processedEvent)
            processEvent.fulfill()
        }

        let model = MockSynced(id: "id-1")
        let anyModel = try model.eraseToAnyModel()
        let remoteSyncMetadata = MutationSyncMetadata(id: model.id,
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

    func testRecievedStartActionWhileExpectingEventProcessedAction() throws {
        //Ensure subscription is setup
        let receivedSubscription = expectation(description: "receivedSubscription")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.receivedSubscription)
            receivedSubscription.fulfill()
        }
        stateMachine.state = .starting(apiBehavior, publisher)
        wait(for: [receivedSubscription], timeout: 200)

        //Mock incoming mutation event
        let post = Post(title: "title",
                        content: "content",
                        createdAt: .now())
        let futureResult = try MutationEvent(model: post,
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
        wait(for: [enqueueEvent, mutateAPICallExpecation], timeout: 200)

        // While we are expecting the mutationEvent to be processed by making an API call.
        // pause the mutation queue.  Note that we are not testing that the operation
        // actually gets paused, the purpose of this test is to test the state transition
        // when we call startSyncingToCloud()
        mutationQueue.pauseSyncingToCloud()

        //Re-enable syncing
        let startRecievedAgain = expectation(description: "Start recieved again")
        let resumeSyncingToCloud = expectation(description: "Resume sync to cloud")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.receivedStart(self.apiBehavior,
                                                                              self.publisher))
            startRecievedAgain.fulfill()
        }
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.resumedSyncingToCloud)
            resumeSyncingToCloud.fulfill()
        }

        mutationQueue.startSyncingToCloud(api: apiBehavior,
                                          mutationEventPublisher: publisher)
        stateMachine.state = .resumingMutationQueue

        wait(for: [startRecievedAgain, resumeSyncingToCloud], timeout: 1)

        //After - enabling, mock the callback from API to be completed
        let processEvent = expectation(description: "state requestingEvent, processedEvent")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.processedEvent)
            processEvent.fulfill()
        }

        let model = MockSynced(id: "id-1")
        let anyModel = try model.eraseToAnyModel()
        let remoteSyncMetadata = MutationSyncMetadata(id: model.id,
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
        case (.notStarted, .notStarted):
            return true
        case (.starting, .starting):
            return true
        case (.requestingEvent, .requestingEvent):
            return true
        case (.waitingForEventToProcess, .waitingForEventToProcess):
            return true
        case (.finished, .finished):
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
        case (.receivedCancel, .receivedCancel):
            return true
        case (.resumedSyncingToCloud, .resumedSyncingToCloud):
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

    private func setUpCore() throws -> AmplifyConfiguration {
        Amplify.reset()

        let storageEngine = MockStorageEngineBehavior()
        let dataStorePublisher = DataStorePublisher()
        let dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                                 storageEngine: storageEngine,
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

    private func setUpWithAPI() throws {
        let configWithoutAPI = try setUpCore()
        let configWithAPI = try setUpAPICategory(config: configWithoutAPI)
        try Amplify.configure(configWithAPI)
    }

}
