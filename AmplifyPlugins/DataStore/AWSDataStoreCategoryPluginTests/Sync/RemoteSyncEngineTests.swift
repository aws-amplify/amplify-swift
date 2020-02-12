//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite

import Combine
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class RemoteEngineSyncTests: XCTestCase {
    var apiPlugin: MockAPICategoryPlugin!

    var amplifyConfig: AmplifyConfiguration!
    var storageAdapter: StorageEngineAdapter!
    var remoteSyncEngine: RemoteSyncEngine!
    let defaultAsyncWaitTimeout = 2.0

    override func setUp() {
        super.setUp()
        MockAWSInitialSyncOrchestrator.reset()
        storageAdapter = MockSQLiteStorageEngineAdapter()
        let mockOutgoingMutationQueue = MockOutgoingMutationQueue()
        do {
            remoteSyncEngine = try RemoteSyncEngine(storageAdapter: storageAdapter,
                                                    outgoingMutationQueue: mockOutgoingMutationQueue,
                                                    initialSyncOrchestratorFactory: MockAWSInitialSyncOrchestrator.factory,
                                                    reconciliationQueueFactory: MockAWSIncomingEventReconciliationQueue.factory)
        } catch {
            XCTFail("Failed to setup")
            return
        }
    }

    func testErrorOnNilStorageAdapter() throws {
        let failureOnStorageAdapter = expectation(description: "Expect receiveCompletion on storageAdapterFailure")

        storageAdapter = nil
        let remoteSyncEngineSink = remoteSyncEngine
            .publisher
            .sink(receiveCompletion: { _ in
                failureOnStorageAdapter.fulfill()
        }, receiveValue: { _ in
            XCTFail("We should not expect the sync engine not to continue")
        })

        remoteSyncEngine.start()

        wait(for: [failureOnStorageAdapter], timeout: defaultAsyncWaitTimeout)
    }

    //TODO: This unit test captures current behavior which doesn't accurately
    //      reflect what we should be doing.  We should be attempting to retry
    //      the initial sync rather than just failing and propagating up this error.
    func testFailureOnInitialSync() throws {
        let storageAdapterAvailable = expectation(description: "storageAdapterAvailable")
        let mutationsPaused = expectation(description: "mutationsPaused")
        let subscriptionsInitialized = expectation(description: "subscriptionsInitialized")
        let failureOnInitialSync = expectation(description: "failureOnInitialSync")

        var currCount = 1

        let remoteSyncEngineSink = remoteSyncEngine
            .publisher
            .sink(receiveCompletion: { _ in
                currCount = self.checkAndFulfill(currCount, 4, expectation: failureOnInitialSync)
            }, receiveValue: { event in
                switch event {
                case .storageAdapterAvailable:
                    currCount = self.checkAndFulfill(currCount, 1, expectation: storageAdapterAvailable)
                case .subscriptionsPaused:
                    XCTFail("subscriptions have not been created, so they are not paused")
                case .mutationsPaused:
                    currCount = self.checkAndFulfill(currCount, 2, expectation: mutationsPaused)
                case .subscriptionsInitialized:
                    currCount = self.checkAndFulfill(currCount, 3, expectation: subscriptionsInitialized)
                case .performedInitialSync:
                    XCTFail("performedInitialQueries should not be successful")
                default:
                    XCTFail("Unexpected case gets hit")
                }
            })
        MockAWSInitialSyncOrchestrator.setResponseOnSync(result:
            .failure(DataStoreError.internalOperation("forceError", "none", nil)))

        remoteSyncEngine.start()

        wait(for: [storageAdapterAvailable,
                   mutationsPaused, subscriptionsInitialized,
                   failureOnInitialSync], timeout: defaultAsyncWaitTimeout)
    }

    func testRemoteSyncEngineHappyPath() throws {
        let storageAdapterAvailable = expectation(description: "storageAdapterAvailable")
        let mutationsPaused = expectation(description: "mutationsPaused")
        let subscriptionsInitialized = expectation(description: "subscriptionsInitialized")
        let performedInitialSync = expectation(description: "performedInitialSync")
        let subscriptionActivation = expectation(description: "failureOnSubscriptionActivation")
        let mutationQueueStarted = expectation(description: "mutationQueueStarted")
        let syncStarted = expectation(description: "sync started")

        var currCount = 1

        let remoteSyncEngineSink = remoteSyncEngine
            .publisher
            .sink(receiveCompletion: { _ in
                XCTFail("Completion should never happen")
            }, receiveValue: { event in
                switch event {
                case .storageAdapterAvailable:
                    currCount = self.checkAndFulfill(currCount, 1, expectation: storageAdapterAvailable)
                case .subscriptionsPaused:
                    XCTFail("subscriptions have not been created, so they are not paused")
                case .mutationsPaused:
                    currCount = self.checkAndFulfill(currCount, 2, expectation: mutationsPaused)
                case .subscriptionsInitialized:
                    currCount = self.checkAndFulfill(currCount, 3, expectation: subscriptionsInitialized)
                case .performedInitialSync:
                    currCount = self.checkAndFulfill(currCount, 4, expectation: performedInitialSync)
                case .subscriptionsActivated:
                    currCount = self.checkAndFulfill(currCount, 5, expectation: subscriptionActivation)
                case .mutationQueueStarted:
                    currCount = self.checkAndFulfill(currCount, 6, expectation: mutationQueueStarted)
                case .syncStarted:
                    currCount = self.checkAndFulfill(currCount, 7, expectation: syncStarted)
                default:
                    XCTFail("unexpected call")
                }
            })

        remoteSyncEngine.start()

        wait(for: [storageAdapterAvailable,
                   mutationsPaused,
                   subscriptionsInitialized,
                   performedInitialSync,
                   subscriptionActivation,
                   mutationQueueStarted,
                   syncStarted], timeout: defaultAsyncWaitTimeout)
    }

    func testCatastrophicErrorEndsRemoteSyncEngine() throws {
        let storageAdapterAvailable = expectation(description: "storageAdapterAvailable")
        let mutationsPaused = expectation(description: "mutationsPaused")
        let subscriptionsInitialized = expectation(description: "subscriptionsInitialized")
        let performedInitialSync = expectation(description: "performedInitialSync")
        let subscriptionActivation = expectation(description: "failureOnSubscriptionActivation")
        let mutationQueueStarted = expectation(description: "mutationQueueStarted")
        let syncStarted = expectation(description: "sync started")
        let syncStopped = expectation(description: "sync stopped")
        let apiFailed = expectation(description: "API Failed")

        var currCount = 1

        let remoteSyncEngineSink = remoteSyncEngine
            .publisher
            .sink(receiveCompletion: { _ in
                currCount = self.checkAndFulfill(currCount, 9, expectation: apiFailed)
            }, receiveValue: { event in
                switch event {
                case .storageAdapterAvailable:
                    currCount = self.checkAndFulfill(currCount, 1, expectation: storageAdapterAvailable)
                case .subscriptionsPaused:
                    XCTFail("subscriptions have not been created, so they are not paused")
                case .mutationsPaused:
                    currCount = self.checkAndFulfill(currCount, 2, expectation: mutationsPaused)
                case .subscriptionsInitialized:
                    currCount = self.checkAndFulfill(currCount, 3, expectation: subscriptionsInitialized)
                case .performedInitialSync:
                    currCount = self.checkAndFulfill(currCount, 4, expectation: performedInitialSync)
                case .subscriptionsActivated:
                    currCount = self.checkAndFulfill(currCount, 5, expectation: subscriptionActivation)
                case .mutationQueueStarted:
                    currCount = self.checkAndFulfill(currCount, 6, expectation: mutationQueueStarted)
                case .syncStarted:
                    currCount = self.checkAndFulfill(currCount, 7, expectation: syncStarted)
                    MockAWSIncomingEventReconciliationQueue.mockSendCompletion(completion: .finished)
                case .syncStopped:
                    currCount = self.checkAndFulfill(currCount, 8, expectation: syncStopped)
                default:
                    XCTFail("unexpected call")
                }
            })

        remoteSyncEngine.start()

        wait(for: [storageAdapterAvailable,
                   mutationsPaused,
                   subscriptionsInitialized,
                   performedInitialSync,
                   subscriptionActivation,
                   mutationQueueStarted,
                   syncStarted,
                   syncStopped,
                   apiFailed], timeout: defaultAsyncWaitTimeout)
    }

    func checkAndFulfill(_ currCount: Int, _ expectedCount: Int, expectation: XCTestExpectation) -> Int {
        if currCount == expectedCount {
            expectation.fulfill()
            return currCount + 1
        }
        return currCount
    }
}
