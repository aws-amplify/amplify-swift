//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

class AutoUnsubscribeOperationTests: XCTestCase {

    override func setUp() async throws {
        await Amplify.reset()

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

    override func tearDown() async throws {
        await Amplify.reset()
    }

    /// - Given: An Amplify operation class
    /// - When: I pass an event listener with no other options to the operation constructor
    /// - Then: The event listener is unsubscribed when it receives a successful result
    func testOperationUnsubscribesOnSuccess() throws {
        throw XCTSkip("Storage listeners removed")
        // TODO: consider rewriting with async API

//        let listenerWasInvokedForInProcess = expectation(description: "listener was invoked for in process event")
//        listenerWasInvokedForInProcess.isInverted = true
//
//        let listenerWasInvokedForCompleted = expectation(description: "listener was invoked for completed event")
//
//        let listenerWasInvokedForFailed = expectation(description: "listener was invoked for failed event")
//        listenerWasInvokedForFailed.isInverted = true
//
//        let progressListener: ProgressListener = { _ in listenerWasInvokedForInProcess.fulfill() }
//
//        let amplifyOperation = Amplify.Storage.downloadData(
//            key: "foo",
//            progressListener: progressListener
//        ) { result in
//            switch result {
//            case .success:
//                listenerWasInvokedForCompleted.fulfill()
//            case .failure:
//                listenerWasInvokedForFailed.fulfill()
//            }
//        }
//
//        guard let operation = amplifyOperation as? MockDispatchingStorageDownloadDataOperation else {
//            XCTFail("Unable to cast amplifyOperation as MockDispatchingStorageListOperation")
//            return
//        }
//
//        operation.doMockDispatch()
//        await fulfillment(of: [listenerWasInvokedForCompleted], timeout: 0.1)
//
//        operation.doMockProgress()
//        operation.doMockDispatch(result: .failure(StorageError.accessDenied("", "")))
//        await fulfillment(of: [listenerWasInvokedForInProcess, listenerWasInvokedForFailed], timeout: 0.1)
    }

    /// - Given: An Amplify operation class
    /// - When: I pass an event listener with no other options to the operation constructor
    /// - Then: The event listener is unsubscribed when it receives a terminal event (.error)
    func testOperationUnsubscribesOnError() throws {
        throw XCTSkip("Storage listeners removed")
        // TODO: consider rewriting with async API

//        let listenerWasInvokedForInProcess = expectation(description: "listener was invoked for in process event")
//        listenerWasInvokedForInProcess.isInverted = true
//
//        let listenerWasInvokedForCompleted = expectation(description: "listener was invoked for completed event")
//        listenerWasInvokedForCompleted.isInverted = true
//
//        let listenerWasInvokedForFailed = expectation(description: "listener was invoked for failed event")
//
//        let progressListener: ProgressListener = { _ in listenerWasInvokedForInProcess.fulfill() }
//
//        let amplifyOperation = Amplify.Storage.downloadData(
//            key: "foo",
//            progressListener: progressListener
//        ) { result in
//            switch result {
//            case .success:
//                listenerWasInvokedForCompleted.fulfill()
//            case .failure:
//                listenerWasInvokedForFailed.fulfill()
//            }
//        }
//
//        guard let operation = amplifyOperation as? MockDispatchingStorageDownloadDataOperation else {
//            XCTFail("Unable to cast amplifyOperation as MockDispatchingStorageListOperation")
//            return
//        }
//
//        operation.doMockDispatch(result: .failure(StorageError.accessDenied("", "")))
//        await fulfillment(of: [listenerWasInvokedForFailed], timeout: 0.1)
//
//        operation.doMockProgress()
//        operation.doMockDispatch()
//        await fulfillment(of: [listenerWasInvokedForInProcess, listenerWasInvokedForCompleted], timeout: 0.1)
    }

    /// - Given: An Amplify operation class
    /// - When: I pass an event listener with no other options to the operation constructor
    /// - Then: The event listener is unsubscribed when it receives a terminal event (.completed) after processing in-
    ///         progress events
    func testOperationUnsubscribesOnCompleteAfterProgress() throws {
        throw XCTSkip("Storage listeners removed")
        // TODO: consider rewriting with async API

//        let listenerWasInvokedForInProcess = expectation(description: "listener was invoked for in process event")
//
//        let listenerWasInvokedForCompleted = expectation(description: "listener was invoked for completed event")
//
//        let listenerWasInvokedForFailed = expectation(description: "listener was invoked for failed event")
//        listenerWasInvokedForFailed.isInverted = true
//
//        let progressListener: ProgressListener = { _ in listenerWasInvokedForInProcess.fulfill() }
//
//        let amplifyOperation = Amplify.Storage.downloadData(
//            key: "foo",
//            progressListener: progressListener
//        ) { result in
//            switch result {
//            case .success:
//                listenerWasInvokedForCompleted.fulfill()
//            case .failure:
//                listenerWasInvokedForFailed.fulfill()
//            }
//        }
//
//        guard let operation = amplifyOperation as? MockDispatchingStorageDownloadDataOperation else {
//            XCTFail("Unable to cast amplifyOperation as MockDispatchingStorageListOperation")
//            return
//        }
//
//        operation.doMockProgress()
//        operation.doMockDispatch()
//        await fulfillment(of: [listenerWasInvokedForInProcess, listenerWasInvokedForCompleted], timeout: 0.1)
//
//        operation.doMockDispatch(result: .failure(StorageError.accessDenied("", "")))
//        await fulfillment(of: [listenerWasInvokedForFailed], timeout: 0.1)
    }

    /// - Given: An Amplify operation class
    /// - When: I pass an event listener with no other options to the operation constructor
    /// - Then: The event listener is unsubscribed when it receives a terminal event (.error) after processing in-
    ///         progress events
    func testOperationUnsubscribesOnErrorAfterProgress() throws {
        throw XCTSkip("Storage listeners removed")
        // TODO: consider rewriting with async API

//        let listenerWasInvokedForInProcess = expectation(description: "listener was invoked for in process event")
//
//        let listenerWasInvokedForCompleted = expectation(description: "listener was invoked for completed event")
//        listenerWasInvokedForCompleted.isInverted = true
//
//        let listenerWasInvokedForFailed = expectation(description: "listener was invoked for failed event")
//
//        let progressListener: ProgressListener = { _ in listenerWasInvokedForInProcess.fulfill() }
//
//        let amplifyOperation = Amplify.Storage.downloadData(
//            key: "foo",
//            progressListener: progressListener
//        ) { result in
//            switch result {
//            case .success:
//                listenerWasInvokedForCompleted.fulfill()
//            case .failure:
//                listenerWasInvokedForFailed.fulfill()
//            }
//        }
//
//        guard let operation = amplifyOperation as? MockDispatchingStorageDownloadDataOperation else {
//            XCTFail("Unable to cast amplifyOperation as MockDispatchingStorageListOperation")
//            return
//        }
//
//        operation.doMockProgress()
//        operation.doMockDispatch(result: .failure(StorageError.accessDenied("", "")))
//        await fulfillment(of: [listenerWasInvokedForInProcess, listenerWasInvokedForFailed], timeout: 0.1)
//
//        operation.doMockProgress()
//        await fulfillment(of: [listenerWasInvokedForCompleted], timeout: 0.1)
    }

}
