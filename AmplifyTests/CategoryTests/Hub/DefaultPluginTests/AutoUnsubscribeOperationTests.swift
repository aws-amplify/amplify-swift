//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

class AutoUnsubscribeOperationTests: XCTestCase {

    override func setUp() {
        Amplify.reset()

        let storageConfiguration =
            StorageCategoryConfiguration(plugins: ["MockDispatchingStoragePlugin": nil])
        let config = AmplifyConfiguration(storage: storageConfiguration)
        do {
            try Amplify.add(plugin: MockDispatchingStoragePlugin())
            try Amplify.configure(config)
        } catch {
            XCTFail("Error setting up Amplify: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    /// - Given: An Amplify operation class
    /// - When: I pass an event listener with no other options to the operation constructor
    /// - Then: The event listener is unsubscribed when it receives a terminal event (.completed)
    func testOperationUnsubscribesOnComplete() throws {
        let listenerWasInvokedForInProcess = expectation(description: "listener was invoked for in process event")
        listenerWasInvokedForInProcess.isInverted = true

        let listenerWasInvokedForCompleted = expectation(description: "listener was invoked for completed event")

        let listenerWasInvokedForFailed = expectation(description: "listener was invoked for failed event")
        listenerWasInvokedForFailed.isInverted = true

        let amplifyOperation = Amplify.Storage.list { event in
            switch event {
            case .inProcess:
                listenerWasInvokedForInProcess.fulfill()
            case .completed:
                listenerWasInvokedForCompleted.fulfill()
            case .failed:
                listenerWasInvokedForFailed.fulfill()
            default:
                break
            }
        }

        guard let operation = amplifyOperation as? MockDispatchingStorageListOperation else {
            XCTFail("Unable to cast amplifyOperation as MockDispatchingStorageListOperation")
            return
        }

        operation.doMockDispatch(event: .completed(StorageListResult(keys: [])))
        wait(for: [listenerWasInvokedForCompleted], timeout: 0.1)

        operation.doMockDispatch(event: .inProcess(()))
        operation.doMockDispatch(event: .failed(StorageError.accessDenied("", "")))
        wait(for: [listenerWasInvokedForInProcess, listenerWasInvokedForFailed], timeout: 0.1)
    }

    /// - Given: An Amplify operation class
    /// - When: I pass an event listener with no other options to the operation constructor
    /// - Then: The event listener is unsubscribed when it receives a terminal event (.error)
    func testOperationUnsubscribesOnError() throws {
        let listenerWasInvokedForInProcess = expectation(description: "listener was invoked for in process event")
        listenerWasInvokedForInProcess.isInverted = true

        let listenerWasInvokedForCompleted = expectation(description: "listener was invoked for completed event")
        listenerWasInvokedForCompleted.isInverted = true

        let listenerWasInvokedForFailed = expectation(description: "listener was invoked for failed event")

        let amplifyOperation = Amplify.Storage.list { event in
            switch event {
            case .inProcess:
                listenerWasInvokedForInProcess.fulfill()
            case .completed:
                listenerWasInvokedForCompleted.fulfill()
            case .failed:
                listenerWasInvokedForFailed.fulfill()
            default:
                break
            }
        }

        guard let operation = amplifyOperation as? MockDispatchingStorageListOperation else {
            XCTFail("Unable to cast amplifyOperation as MockDispatchingStorageListOperation")
            return
        }

        operation.doMockDispatch(event: .failed(StorageError.accessDenied("", "")))
        wait(for: [listenerWasInvokedForFailed], timeout: 0.1)

        operation.doMockDispatch(event: .inProcess(()))
        operation.doMockDispatch(event: .completed(StorageListResult(keys: [])))
        wait(for: [listenerWasInvokedForInProcess, listenerWasInvokedForCompleted], timeout: 0.1)
    }

    /// - Given: An Amplify operation class
    /// - When: I pass an event listener with no other options to the operation constructor
    /// - Then: The event listener is unsubscribed when it receives a terminal event (.completed) after processing in-
    ///         progress events
    func testOperationUnsubscribesOnCompleteAfterProgress() throws {
        let listenerWasInvokedForInProcess = expectation(description: "listener was invoked for in process event")

        let listenerWasInvokedForCompleted = expectation(description: "listener was invoked for completed event")

        let listenerWasInvokedForFailed = expectation(description: "listener was invoked for failed event")
        listenerWasInvokedForFailed.isInverted = true

        let amplifyOperation = Amplify.Storage.list { event in
            switch event {
            case .inProcess:
                listenerWasInvokedForInProcess.fulfill()
            case .completed:
                listenerWasInvokedForCompleted.fulfill()
            case .failed:
                listenerWasInvokedForFailed.fulfill()
            default:
                break
            }
        }

        guard let operation = amplifyOperation as? MockDispatchingStorageListOperation else {
            XCTFail("Unable to cast amplifyOperation as MockDispatchingStorageListOperation")
            return
        }

        operation.doMockDispatch(event: .inProcess(()))
        operation.doMockDispatch(event: .completed(StorageListResult(keys: [])))
        wait(for: [listenerWasInvokedForInProcess, listenerWasInvokedForCompleted], timeout: 0.1)

        operation.doMockDispatch(event: .failed(StorageError.accessDenied("", "")))
        wait(for: [listenerWasInvokedForFailed], timeout: 0.1)
    }

    /// - Given: An Amplify operation class
    /// - When: I pass an event listener with no other options to the operation constructor
    /// - Then: The event listener is unsubscribed when it receives a terminal event (.error) after processing in-
    ///         progress events
    func testOperationUnsubscribesOnErrorAfterProgress() throws {
        let listenerWasInvokedForInProcess = expectation(description: "listener was invoked for in process event")

        let listenerWasInvokedForCompleted = expectation(description: "listener was invoked for completed event")
        listenerWasInvokedForCompleted.isInverted = true

        let listenerWasInvokedForFailed = expectation(description: "listener was invoked for failed event")

        let amplifyOperation = Amplify.Storage.list { event in
            switch event {
            case .inProcess:
                listenerWasInvokedForInProcess.fulfill()
            case .completed:
                listenerWasInvokedForCompleted.fulfill()
            case .failed:
                listenerWasInvokedForFailed.fulfill()
            default:
                break
            }
        }

        guard let operation = amplifyOperation as? MockDispatchingStorageListOperation else {
            XCTFail("Unable to cast amplifyOperation as MockDispatchingStorageListOperation")
            return
        }

        operation.doMockDispatch(event: .inProcess(()))
        operation.doMockDispatch(event: .failed(StorageError.accessDenied("", "")))
        wait(for: [listenerWasInvokedForInProcess, listenerWasInvokedForFailed], timeout: 0.1)

        operation.doMockDispatch(event: .completed(StorageListResult(keys: [])))
        wait(for: [listenerWasInvokedForCompleted], timeout: 0.1)
    }

}
