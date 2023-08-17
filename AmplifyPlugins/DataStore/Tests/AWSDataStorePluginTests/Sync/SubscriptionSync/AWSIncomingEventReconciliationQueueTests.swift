//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStorePlugin

class AWSIncomingEventReconciliationQueueTests: XCTestCase {
    var storageAdapter: MockSQLiteStorageEngineAdapter!
    var apiPlugin: MockAPICategoryPlugin!

    override func setUp() {
        MockModelReconciliationQueue.reset()
        storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.returnOnQuery(dataStoreResult: .none)
        storageAdapter.returnOnSave(dataStoreResult: .none)

        apiPlugin = MockAPICategoryPlugin()

        operationQueue = OperationQueue()
        operationQueue.name = "com.amazonaws.DataStore.UnitTestQueue"
        operationQueue.maxConcurrentOperationCount = 2
        operationQueue.underlyingQueue = DispatchQueue.global()
        operationQueue.isSuspended = true

    }
    var operationQueue: OperationQueue!

    func initEventQueue(modelSchemas: [ModelSchema]) async -> AWSIncomingEventReconciliationQueue {
        let modelReconciliationQueueFactory = MockModelReconciliationQueue.init
        return await AWSIncomingEventReconciliationQueue(
            modelSchemas: modelSchemas,
            api: apiPlugin,
            storageAdapter: storageAdapter,
            syncExpressions: [],
            authModeStrategy: AWSDefaultAuthModeStrategy(),
            modelReconciliationQueueFactory: modelReconciliationQueueFactory)
    }

    // This test case attempts to hit a race condition, and may be required to execute multiple times
    // in order to demonstrate the bug
    func testTwoConnectionStatusUpdatesAtSameTime() async {
        let expectStarted = expectation(description: "eventQueue expected to send out started state")
        let expectInitialized = expectation(description: "eventQueue expected to send out initialized state")

        let eventQueue = await initEventQueue(modelSchemas: [Post.schema, Comment.schema])
        eventQueue.start()

        // We need to keep this in scope for the duration of the test or else Combine will release the listeners.
        let sink = eventQueue.publisher.sink(receiveCompletion: { _ in
            XCTFail("Not expecting this to call")
        }, receiveValue: { event  in
            switch event {
            case .idle:
                break
            case .started:
                expectStarted.fulfill()
            case .initialized:
                expectInitialized.fulfill()
            default:
                XCTFail("Should not expect any other state, received: \(event)")
            }
        })

        let reconciliationQueues = MockModelReconciliationQueue.mockModelReconciliationQueues
        for (queueName, queue) in reconciliationQueues {
            let cancellableOperation = CancelAwareBlockOperation {
                queue.modelReconciliationQueueSubject.send(.connected(modelName: queueName))
            }
            operationQueue.addOperation(cancellableOperation)
        }
        operationQueue.isSuspended = false
        await fulfillment(of: [expectStarted, expectInitialized], timeout: 2)

        // Take action on the sink to prevent compiler warnings about unused variables.
        sink.cancel()
    }

    func testSubscriptionFailedWithSingleModelUnauthorizedError() async {
        let expectStarted = expectation(description: "eventQueue expected to send out started state")
        let expectInitialized = expectation(description: "eventQueue expected to send out initialized state")
        let eventQueue = await initEventQueue(modelSchemas: [Post.schema])
        eventQueue.start()

        let sink = eventQueue.publisher.sink(receiveCompletion: { _ in
            XCTFail("Not expecting this to call")
        }, receiveValue: { event  in
            switch event {
            case .idle:
                break
            case .started:
                expectStarted.fulfill()
            case .initialized:
                expectInitialized.fulfill()
            default:
                XCTFail("Should not expect any other state, received: \(event)")
            }
        })

        let reconciliationQueues = MockModelReconciliationQueue.mockModelReconciliationQueues
        for (queueName, queue) in reconciliationQueues {
            let cancellableOperation = CancelAwareBlockOperation {
                queue.modelReconciliationQueueSubject.send(.disconnected(modelName: queueName, reason: .unauthorized))
            }
            operationQueue.addOperation(cancellableOperation)
        }
        operationQueue.isSuspended = false
        await fulfillment(of: [expectStarted, expectInitialized], timeout: 2)

        sink.cancel()
    }

    // This test case tests that initialized event is received even if only one
    // model subscriptions out of two failed - Post subscription will fail but Comment will succeed
    func testSubscriptionFailedWithMultipleModels() async {
        let expectStarted = expectation(description: "eventQueue expected to send out started state")
        let expectInitialized = expectation(description: "eventQueue expected to send out initialized state")
        let eventQueue = await initEventQueue(modelSchemas: [Post.schema, Comment.schema])
        eventQueue.start()

        let sink = eventQueue.publisher.sink(receiveCompletion: { _ in
            XCTFail("Not expecting this to call")
        }, receiveValue: { event  in
            switch event {
            case .idle:
                break
            case .started:
                expectStarted.fulfill()
            case .initialized:
                expectInitialized.fulfill()
            default:
                XCTFail("Should not expect any other state, received: \(event)")
            }
        })

        let reconciliationQueues = MockModelReconciliationQueue.mockModelReconciliationQueues
        for (queueName, queue) in reconciliationQueues {
            let cancellableOperation = CancelAwareBlockOperation {
                let event: ModelReconciliationQueueEvent = queueName == Post.modelName ?
                    .disconnected(modelName: queueName, reason: .unauthorized) :
                    .connected(modelName: queueName)
                queue.modelReconciliationQueueSubject.send(event)
            }
            operationQueue.addOperation(cancellableOperation)
        }
        operationQueue.isSuspended = false
        await fulfillment(of: [expectStarted, expectInitialized], timeout: 2)

        sink.cancel()
    }

    func testSubscriptionFailedWithSingleModelOperationDisabled() async {
        let expectStarted = expectation(description: "eventQueue expected to send out started state")
        let expectInitialized = expectation(description: "eventQueue expected to send out initialized state")
        let eventQueue = await initEventQueue(modelSchemas: [Post.schema])
        eventQueue.start()

        let sink = eventQueue.publisher.sink(receiveCompletion: { _ in
            XCTFail("Not expecting this to call")
        }, receiveValue: { event  in
            switch event {
            case .idle:
                break
            case .started:
                expectStarted.fulfill()
            case .initialized:
                expectInitialized.fulfill()
            default:
                XCTFail("Should not expect any other state, received: \(event)")
            }
        })

        let reconciliationQueues = MockModelReconciliationQueue.mockModelReconciliationQueues
        for (queueName, queue) in reconciliationQueues {
            let cancellableOperation = CancelAwareBlockOperation {
                queue.modelReconciliationQueueSubject.send(
                    .disconnected(modelName: queueName, reason: .operationDisabled))
            }
            operationQueue.addOperation(cancellableOperation)
        }
        operationQueue.isSuspended = false
        await fulfillment(of: [expectStarted, expectInitialized], timeout: 2)

        sink.cancel()
    }

    // This test case tests that initialized event is received even if only one
    // model subscriptions out of two succeeded
    // Post subscription will fail with a "OperationDisabled",
    // but Comment subscription will succeed
    func testSubscriptionFailedBecauseOfOperationDisabledWithMultipleModels() async {
        let expectStarted = expectation(description: "eventQueue expected to send out started state")
        let expectInitialized = expectation(description: "eventQueue expected to send out initialized state")
        let eventQueue = await initEventQueue(modelSchemas: [Post.schema])
        eventQueue.start()

        let sink = eventQueue.publisher.sink(receiveCompletion: { _ in
            XCTFail("Not expecting this to call")
        }, receiveValue: { event  in
            switch event {
            case .idle:
                break
            case .started:
                expectStarted.fulfill()
            case .initialized:
                expectInitialized.fulfill()
            default:
                XCTFail("Should not expect any other state, received: \(event)")
            }
        })
        
        let reconciliationQueues = MockModelReconciliationQueue.mockModelReconciliationQueues
        for (queueName, queue) in reconciliationQueues {
            let cancellableOperation = CancelAwareBlockOperation {
                let event: ModelReconciliationQueueEvent = queueName == Post.modelName ?
                    .disconnected(modelName: queueName, reason: .operationDisabled) :
                    .connected(modelName: queueName)
                queue.modelReconciliationQueueSubject.send(event)
            }
            operationQueue.addOperation(cancellableOperation)
        }
        operationQueue.isSuspended = false
        await fulfillment(of: [expectStarted, expectInitialized], timeout: 2)

        sink.cancel()

    }
}
