//
// Copyright 2018-2019 Amazon.com,
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
        mutationQueue = OutgoingMutationQueue(stateMachine)
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

        mutationQueue = OutgoingMutationQueue(stateMachine)
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

    func testRequestingEvent_subscriptionSetup() {
        let semaphore = DispatchSemaphore(value: 0)
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.receivedSubscription)
            semaphore.signal()
        }
        stateMachine.state = .starting(apiBehavior, publisher)
        semaphore.wait()

        let enqueueEvent = expectation(description: "state requestingEvent, enqueueEvent")
        let processEvent = expectation(description: "state requestingEvent, processedEvent")
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.enqueuedEvent)
            enqueueEvent.fulfill()
        }
        stateMachine.pushExpectActionCriteria { action in
            XCTAssertEqual(action, OutgoingMutationQueue.Action.processedEvent)
            processEvent.fulfill()
        }
        stateMachine.state = .requestingEvent

        waitForExpectations(timeout: 1)
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
        case (.errored, .errored):
            return true
        default:
            return false
        }
    }
}

class MockMutationEventSource: MutationEventSource {

    func getNextMutationEvent(completion: @escaping DataStoreCallback<MutationEvent>) {
        //TODO: Make generic to handle the error cases
        var mutationEvent = MutationEvent(modelId: "1",
                                          modelName: "Post",
                                          json: "{}",
                                          mutationType: MutationEvent.MutationType.create)
        completion(.success(mutationEvent))
    }
}

extension OutgoingMutationQueueMockStateTest {
    private func setUpCore() throws -> AmplifyConfiguration {
        Amplify.reset()

        let storageEngine = MockStorageEngineBehavior()
        let dataStorePublisher = DataStorePublisher()
        let dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                                 storageEngine: storageEngine,
                                                 dataStorePublisher: dataStorePublisher)
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
