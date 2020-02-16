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

    func testFailureOnInitialSync() throws {
        let storageAdapterAvailable = expectation(description: "storageAdapterAvailable")
        let subscriptionsPaused = expectation(description: "subscriptionsPaused")
        let mutationsPaused = expectation(description: "mutationsPaused")
        let subscriptionsInitialized = expectation(description: "subscriptionsInitialized")
        let failureOnInitialSync = expectation(description: "failureOnInitialSync")

        let remoteSyncEngineSink = remoteSyncEngine
            .publisher
            .sink(receiveCompletion: { _ in
                failureOnInitialSync.fulfill()
            }, receiveValue: { event in
                switch event {
                case .storageAdapterAvailable:
                    storageAdapterAvailable.fulfill()
                case .subscriptionsPaused:
                    subscriptionsPaused.fulfill()
                case .mutationsPaused:
                    mutationsPaused.fulfill()
                case .subscriptionsInitialized:
                    subscriptionsInitialized.fulfill()
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
                   subscriptionsPaused,
                   mutationsPaused,
                   subscriptionsInitialized,
                   failureOnInitialSync], timeout: defaultAsyncWaitTimeout)
    }

    func testRemoteSyncEngineHappyPath() throws {
        let storageAdapterAvailable = expectation(description: "storageAdapterAvailable")
        let subscriptionsPaused = expectation(description: "subscriptionsPaused")
        let mutationsPaused = expectation(description: "mutationsPaused")
        let subscriptionsInitialized = expectation(description: "subscriptionsInitialized")
        let performedInitialSync = expectation(description: "performedInitialSync")
        let subscriptionActivation = expectation(description: "failureOnSubscriptionActivation")
        let mutationQueueStarted = expectation(description: "mutationQueueStarted")
        let syncStarted = expectation(description: "sync started")

        let remoteSyncEngineSink = remoteSyncEngine
            .publisher
            .sink(receiveCompletion: { _ in
                XCTFail("Completion should never happen")
            }, receiveValue: { event in
                switch event {
                case .storageAdapterAvailable:
                    storageAdapterAvailable.fulfill()
                case .subscriptionsPaused:
                    subscriptionsPaused.fulfill()
                case .mutationsPaused:
                    mutationsPaused.fulfill()
                case .subscriptionsInitialized:
                    subscriptionsInitialized.fulfill()
                case .performedInitialSync:
                    performedInitialSync.fulfill()
                case .subscriptionsActivated:
                    subscriptionActivation.fulfill()
                case .mutationQueueStarted:
                    mutationQueueStarted.fulfill()
                case .syncStarted:
                    syncStarted.fulfill()
                default:
                    XCTFail("unexpected call")
                }
            })

        remoteSyncEngine.start()

        wait(for: [storageAdapterAvailable,
                   subscriptionsPaused,
                   mutationsPaused,
                   subscriptionsInitialized,
                   performedInitialSync,
                   subscriptionActivation,
                   mutationQueueStarted,
                   syncStarted], timeout: defaultAsyncWaitTimeout)
    }

    func testFailsAfterSyncStarted() throws {
        let storageAdapterAvailable = expectation(description: "storageAdapterAvailable")
        let subscriptionsPaused = expectation(description: "subscriptionsPaused")
        let mutationsPaused = expectation(description: "mutationsPaused")
        let subscriptionsInitialized = expectation(description: "subscriptionsInitialized")
        let performedInitialSync = expectation(description: "performedInitialSync")
        let subscriptionActivation = expectation(description: "failureOnSubscriptionActivation")
        let mutationQueueStarted = expectation(description: "mutationQueueStarted")
        let syncStarted = expectation(description: "sync started")
        let failureOnEventReconciliationQueue = expectation(description: "reconciliationQueue failed")

        let remoteSyncEngineSink = remoteSyncEngine
            .publisher
            .sink(receiveCompletion: { _ in
                failureOnEventReconciliationQueue.fulfill()
            }, receiveValue: { event in
                switch event {
                case .storageAdapterAvailable:
                    storageAdapterAvailable.fulfill()
                case .subscriptionsPaused:
                    subscriptionsPaused.fulfill()
                case .mutationsPaused:
                    mutationsPaused.fulfill()
                case .subscriptionsInitialized:
                    subscriptionsInitialized.fulfill()
                case .performedInitialSync:
                    performedInitialSync.fulfill()
                case .subscriptionsActivated:
                    subscriptionActivation.fulfill()
                case .mutationQueueStarted:
                    mutationQueueStarted.fulfill()
                case .syncStarted:
                    syncStarted.fulfill()
                    MockAWSIncomingEventReconciliationQueue.mockSendCompletion(completion: .failure(DataStoreError.unknown("", "", nil)))
                default:
                    XCTFail("unexpected call")
                }
            })

        remoteSyncEngine.start()

        wait(for: [storageAdapterAvailable,
                   subscriptionsPaused,
                   mutationsPaused,
                   subscriptionsInitialized,
                   performedInitialSync,
                   subscriptionActivation,
                   mutationQueueStarted,
                   syncStarted,
                   failureOnEventReconciliationQueue], timeout: defaultAsyncWaitTimeout)
    }
}
