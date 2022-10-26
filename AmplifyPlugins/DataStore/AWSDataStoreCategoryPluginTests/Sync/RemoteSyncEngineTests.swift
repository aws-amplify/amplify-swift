//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite

import Combine
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

// swiftlint:disable all
class RemoteSyncEngineTests: XCTestCase {
    var apiPlugin: MockAPICategoryPlugin!

    var amplifyConfig: AmplifyConfiguration!
    var storageAdapter: StorageEngineAdapter!
    var remoteSyncEngine: RemoteSyncEngine!
    var mockRequestRetryablePolicy: MockRequestRetryablePolicy!

    let defaultAsyncWaitTimeout = 2.0

    override func setUp() {
        super.setUp()
        apiPlugin = MockAPICategoryPlugin()
        MockAWSInitialSyncOrchestrator.reset()
        storageAdapter = MockSQLiteStorageEngineAdapter()
        let mockOutgoingMutationQueue = MockOutgoingMutationQueue()
        mockRequestRetryablePolicy = MockRequestRetryablePolicy()
        do {
            remoteSyncEngine = try RemoteSyncEngine(
                storageAdapter: storageAdapter,
                dataStoreConfiguration: .default,
                outgoingMutationQueue: mockOutgoingMutationQueue,
                initialSyncOrchestratorFactory: MockAWSInitialSyncOrchestrator.factory,
                reconciliationQueueFactory: MockAWSIncomingEventReconciliationQueue.factory,
                requestRetryablePolicy: mockRequestRetryablePolicy
            )
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
        remoteSyncEngineSink.cancel()
    }

    func testFailureOnInitialSync() throws {
        let storageAdapterAvailable = expectation(description: "storageAdapterAvailable")
        let subscriptionsPaused = expectation(description: "subscriptionsPaused")
        let mutationsPaused = expectation(description: "mutationsPaused")
        let stateMutationsCleared = expectation(description: "stateMutationsCleared")
        let subscriptionsInitialized = expectation(description: "subscriptionsInitialized")
        let subscriptionsEstablishedReceived = expectation(description: "subscriptionsEstablished received")
        let cleanedup = expectation(description: "cleanedup")
        let failureOnInitialSync = expectation(description: "failureOnInitialSync")
        let retryAdviceReceivedNetworkError = expectation(description: "retry advice received network error")
        var currCount = 1

        let advice = RequestRetryAdvice.init(shouldRetry: false)
        mockRequestRetryablePolicy.pushOnRetryRequestAdvice(response: advice)
        mockRequestRetryablePolicy.setOnRetryRequestAdvice { urlError, httpURLResponse, attemptNumber in
            XCTAssertNotNil(urlError)
            retryAdviceReceivedNetworkError.fulfill()
        }

        let filter = HubFilters.forEventName(HubPayload.EventName.DataStore.subscriptionsEstablished)
        let hubListener = Amplify.Hub.listen(to: .dataStore, isIncluded: filter) { payload in
            XCTAssertNil(payload.data)
            subscriptionsEstablishedReceived.fulfill()
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        let remoteSyncEngineSink = remoteSyncEngine
            .publisher
            .sink(receiveCompletion: { _ in
                currCount = self.checkAndFulfill(currCount, 7, expectation: failureOnInitialSync)
            }, receiveValue: { event in
                switch event {
                case .storageAdapterAvailable:
                    currCount = self.checkAndFulfill(currCount, 1, expectation: storageAdapterAvailable)
                case .subscriptionsPaused:
                    currCount = self.checkAndFulfill(currCount, 2, expectation: subscriptionsPaused)
                case .mutationsPaused:
                    currCount = self.checkAndFulfill(currCount, 3, expectation: mutationsPaused)
                    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
                        MockAWSIncomingEventReconciliationQueue.mockSend(event: .initialized)
                    }
                case .clearedStateOutgoingMutations:
                    currCount = self.checkAndFulfill(currCount, 4, expectation: stateMutationsCleared)
                case .subscriptionsInitialized:
                    currCount = self.checkAndFulfill(currCount, 5, expectation: subscriptionsInitialized)
                case .performedInitialSync:
                    XCTFail("performedInitialQueries should not be successful")
                case .cleanedUp:
                    currCount = self.checkAndFulfill(currCount, 6, expectation: cleanedup)
                default:
                    XCTFail("Unexpected case gets hit")
                }
            })
        MockAWSInitialSyncOrchestrator.setResponseOnSync(result: .failure(
            DataStoreError.internalOperation("forceError", "none", URLError(.notConnectedToInternet))))

        remoteSyncEngine.start(api: apiPlugin)

        wait(for: [storageAdapterAvailable,
                   subscriptionsPaused,
                   mutationsPaused,
                   stateMutationsCleared,
                   subscriptionsInitialized,
                   subscriptionsEstablishedReceived,
                   cleanedup,
                   failureOnInitialSync,
                   retryAdviceReceivedNetworkError], timeout: defaultAsyncWaitTimeout)
        remoteSyncEngineSink.cancel()
        Amplify.Hub.removeListener(hubListener)
    }
    /* tslint:disable */
    func testRemoteSyncEngineHappyPath() throws {
        let storageAdapterAvailable = expectation(description: "storageAdapterAvailable")
        let subscriptionsPaused = expectation(description: "subscriptionsPaused")
        let mutationsPaused = expectation(description: "mutationsPaused")
        let stateMutationsCleared = expectation(description: "stateMutationsCleared")
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
                    currCount = self.checkAndFulfill(currCount, 2, expectation: subscriptionsPaused)
                case .mutationsPaused:
                    currCount = self.checkAndFulfill(currCount, 3, expectation: mutationsPaused)
                    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
                        MockAWSIncomingEventReconciliationQueue.mockSend(event: .initialized)
                    }
                case .clearedStateOutgoingMutations:
                    currCount = self.checkAndFulfill(currCount, 4, expectation: stateMutationsCleared)
                case .subscriptionsInitialized:
                    currCount = self.checkAndFulfill(currCount, 5, expectation: subscriptionsInitialized)
                case .performedInitialSync:
                    currCount = self.checkAndFulfill(currCount, 6, expectation: performedInitialSync)
                case .subscriptionsActivated:
                    currCount = self.checkAndFulfill(currCount, 7, expectation: subscriptionActivation)
                case .mutationQueueStarted:
                    currCount = self.checkAndFulfill(currCount, 8, expectation: mutationQueueStarted)
                case .syncStarted:
                    currCount = self.checkAndFulfill(currCount, 9, expectation: syncStarted)
                default:
                    XCTFail("unexpected call")
                }
            })

        remoteSyncEngine.start(api: apiPlugin)

        wait(for: [storageAdapterAvailable,
                   subscriptionsPaused,
                   mutationsPaused,
                   stateMutationsCleared,
                   subscriptionsInitialized,
                   performedInitialSync,
                   subscriptionActivation,
                   mutationQueueStarted,
                   syncStarted], timeout: defaultAsyncWaitTimeout)
        remoteSyncEngineSink.cancel()
    }

    // swiftlint:disable:next cyclomatic_complexity
    func testCatastrophicErrorEndsRemoteSyncEngine() throws {
        let storageAdapterAvailable = expectation(description: "storageAdapterAvailable")
        let subscriptionsPaused = expectation(description: "subscriptionsPaused")
        let mutationsPaused = expectation(description: "mutationsPaused")
        let stateMutationsCleared = expectation(description: "stateMutationsCleared")
        let subscriptionsInitialized = expectation(description: "subscriptionsInitialized")
        let performedInitialSync = expectation(description: "performedInitialSync")
        let subscriptionActivation = expectation(description: "failureOnSubscriptionActivation")
        let mutationQueueStarted = expectation(description: "mutationQueueStarted")
        let syncStarted = expectation(description: "syncStarted")
        let cleanedUp = expectation(description: "cleanedUp")
        let forceFailToNotRestartSyncEngine = expectation(description: "forceFailToNotRestartSyncEngine")

        var currCount = 1

        let advice = RequestRetryAdvice.init(shouldRetry: false)
        mockRequestRetryablePolicy.pushOnRetryRequestAdvice(response: advice)

        let remoteSyncEngineSink = remoteSyncEngine
            .publisher
            .sink(receiveCompletion: { _ in
                currCount = self.checkAndFulfill(currCount, 11, expectation: forceFailToNotRestartSyncEngine)
            }, receiveValue: { event in
                switch event {
                case .storageAdapterAvailable:
                    currCount = self.checkAndFulfill(currCount, 1, expectation: storageAdapterAvailable)
                case .subscriptionsPaused:
                    currCount = self.checkAndFulfill(currCount, 2, expectation: subscriptionsPaused)
                case .mutationsPaused:
                    currCount = self.checkAndFulfill(currCount, 3, expectation: mutationsPaused)
                    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
                        MockAWSIncomingEventReconciliationQueue.mockSend(event: .initialized)
                    }
                case .clearedStateOutgoingMutations:
                    currCount = self.checkAndFulfill(currCount, 4, expectation: stateMutationsCleared)
                case .subscriptionsInitialized:
                    currCount = self.checkAndFulfill(currCount, 5, expectation: subscriptionsInitialized)
                case .performedInitialSync:
                    currCount = self.checkAndFulfill(currCount, 6, expectation: performedInitialSync)
                case .subscriptionsActivated:
                    currCount = self.checkAndFulfill(currCount, 7, expectation: subscriptionActivation)
                case .mutationQueueStarted:
                    currCount = self.checkAndFulfill(currCount, 8, expectation: mutationQueueStarted)
                case .syncStarted:
                    currCount = self.checkAndFulfill(currCount, 9, expectation: syncStarted)
                    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
                        MockAWSIncomingEventReconciliationQueue
                            .mockSendCompletion(completion: .failure(DataStoreError.unknown("", "", nil)))
                    }
                case .cleanedUp:
                    currCount = self.checkAndFulfill(currCount, 10, expectation: cleanedUp)
                default:
                    XCTFail("unexpected call")
                }
            })

        remoteSyncEngine.start(api: apiPlugin)

        wait(for: [storageAdapterAvailable,
                   subscriptionsPaused,
                   mutationsPaused,
                   stateMutationsCleared,
                   subscriptionsInitialized,
                   performedInitialSync,
                   subscriptionActivation,
                   mutationQueueStarted,
                   syncStarted,
                   cleanedUp,
                   forceFailToNotRestartSyncEngine], timeout: defaultAsyncWaitTimeout)
        remoteSyncEngineSink.cancel()
    }

    // swiftlint:disable:next cyclomatic_complexity
    func testStopEndsRemoteSyncEngine() throws {
        let storageAdapterAvailable = expectation(description: "storageAdapterAvailable")
        let subscriptionsPaused = expectation(description: "subscriptionsPaused")
        let mutationsPaused = expectation(description: "mutationsPaused")
        let stateMutationsCleared = expectation(description: "stateMutationsCleared")
        let subscriptionsInitialized = expectation(description: "subscriptionsInitialized")
        let performedInitialSync = expectation(description: "performedInitialSync")
        let subscriptionActivation = expectation(description: "failureOnSubscriptionActivation")
        let mutationQueueStarted = expectation(description: "mutationQueueStarted")
        let syncStarted = expectation(description: "syncStarted")
        let cleanedUpForTermination = expectation(description: "cleanedUpForTermination")
        let forceFailToNotRestartSyncEngine = expectation(description: "forceFailToNotRestartSyncEngine")
        let completionBlockCalled = expectation(description: "Completion block is called")

        var currCount = 1

        let advice = RequestRetryAdvice.init(shouldRetry: false)
        mockRequestRetryablePolicy.pushOnRetryRequestAdvice(response: advice)

        let remoteSyncEngineSink = remoteSyncEngine
            .publisher
            .sink(receiveCompletion: { _ in
                currCount = self.checkAndFulfill(currCount, 11, expectation: forceFailToNotRestartSyncEngine)
            }, receiveValue: { event in
                switch event {
                case .storageAdapterAvailable:
                    currCount = self.checkAndFulfill(currCount, 1, expectation: storageAdapterAvailable)
                case .subscriptionsPaused:
                    currCount = self.checkAndFulfill(currCount, 2, expectation: subscriptionsPaused)
                case .mutationsPaused:
                    currCount = self.checkAndFulfill(currCount, 3, expectation: mutationsPaused)
                    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
                        MockAWSIncomingEventReconciliationQueue.mockSend(event: .initialized)
                    }
                case .clearedStateOutgoingMutations:
                    currCount = self.checkAndFulfill(currCount, 4, expectation: stateMutationsCleared)
                case .subscriptionsInitialized:
                    currCount = self.checkAndFulfill(currCount, 5, expectation: subscriptionsInitialized)
                case .performedInitialSync:
                    currCount = self.checkAndFulfill(currCount, 6, expectation: performedInitialSync)
                case .subscriptionsActivated:
                    currCount = self.checkAndFulfill(currCount, 7, expectation: subscriptionActivation)
                case .mutationQueueStarted:
                    currCount = self.checkAndFulfill(currCount, 8, expectation: mutationQueueStarted)
                case .syncStarted:
                    currCount = self.checkAndFulfill(currCount, 9, expectation: syncStarted)
                    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
                        self.remoteSyncEngine.stop(completion: { result in
                            if case .success = result {
                                currCount = self.checkAndFulfill(currCount, 12, expectation: completionBlockCalled)
                            }
                        })
                    }
                case .cleanedUpForTermination:
                    currCount = self.checkAndFulfill(currCount, 10, expectation: cleanedUpForTermination)
                default:
                    XCTFail("unexpected call")
                }
            })

        remoteSyncEngine.start(api: apiPlugin)

        wait(for: [storageAdapterAvailable,
                   subscriptionsPaused,
                   mutationsPaused,
                   stateMutationsCleared,
                   subscriptionsInitialized,
                   performedInitialSync,
                   subscriptionActivation,
                   mutationQueueStarted,
                   syncStarted,
                   cleanedUpForTermination,
                   completionBlockCalled,
                   forceFailToNotRestartSyncEngine], timeout: defaultAsyncWaitTimeout)
        remoteSyncEngineSink.cancel()
    }

    func testStartAndStopStartRemoteSyncEngine() throws {
        let storageAdapterAvailable = expectation(description: "storageAdapterAvailable")
        let subscriptionsPaused = expectation(description: "subscriptionsPaused")
        let mutationsPaused = expectation(description: "mutationsPaused")
        let stateMutationsCleared = expectation(description: "stateMutationsCleared")
        let subscriptionsInitialized = expectation(description: "subscriptionsInitialized")
        let performedInitialSync = expectation(description: "performedInitialSync")
        let subscriptionActivation = expectation(description: "failureOnSubscriptionActivation")
        let mutationQueueStarted = expectation(description: "mutationQueueStarted")
        let syncStarted = expectation(description: "syncStarted")
        let cleanedUpForTermination = expectation(description: "cleanedUpForTermination")
        let forceStopToStopSyncEngine = expectation(description: "forceStopToStopSyncEngine")
        let completionBlockCalled = expectation(description: "Completion block is called")
        let forceStartToRestartSyncEngine = expectation(description: "forceStartToRestartSyncEngine")
        var currCount = 1

        let advice = RequestRetryAdvice.init(shouldRetry: false)
        mockRequestRetryablePolicy.pushOnRetryRequestAdvice(response: advice)

        let remoteSyncEngineSink = remoteSyncEngine
            .publisher
            .sink(receiveCompletion: { _ in
                currCount = self.checkAndFulfill(currCount, 11, expectation: forceStopToStopSyncEngine)
            }, receiveValue: { event in
                switch event {
                case .storageAdapterAvailable:
                    currCount = self.checkAndFulfill(currCount, 1, expectation: storageAdapterAvailable)
                case .subscriptionsPaused:
                    currCount = self.checkAndFulfill(currCount, 2, expectation: subscriptionsPaused)
                case .mutationsPaused:
                    currCount = self.checkAndFulfill(currCount, 3, expectation: mutationsPaused)
                    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
                        MockAWSIncomingEventReconciliationQueue.mockSend(event: .initialized)
                    }
                case .clearedStateOutgoingMutations:
                    currCount = self.checkAndFulfill(currCount, 4, expectation: stateMutationsCleared)
                case .subscriptionsInitialized:
                    currCount = self.checkAndFulfill(currCount, 5, expectation: subscriptionsInitialized)
                case .performedInitialSync:
                    currCount = self.checkAndFulfill(currCount, 6, expectation: performedInitialSync)
                case .subscriptionsActivated:
                    currCount = self.checkAndFulfill(currCount, 7, expectation: subscriptionActivation)
                case .mutationQueueStarted:
                    currCount = self.checkAndFulfill(currCount, 8, expectation: mutationQueueStarted)
                case .syncStarted:
                    currCount = self.checkAndFulfill(currCount, 9, expectation: syncStarted)
                    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
                        self.remoteSyncEngine.stop(completion: { result in
                            if case .success = result {
                                currCount = self.checkAndFulfill(currCount, 12, expectation: completionBlockCalled)
                            }
                        })
                    }
                case .cleanedUpForTermination:
                    currCount = self.checkAndFulfill(currCount, 10, expectation: cleanedUpForTermination)
                    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
                        self.remoteSyncEngine.start()
                        currCount = self.checkAndFulfill(currCount, 13, expectation: forceStartToRestartSyncEngine)
                    }

                default:
                    XCTFail("unexpected call")
                }
            })

        remoteSyncEngine.start(api: apiPlugin)

        wait(for: [storageAdapterAvailable,
                   subscriptionsPaused,
                   mutationsPaused,
                   stateMutationsCleared,
                   subscriptionsInitialized,
                   performedInitialSync,
                   subscriptionActivation,
                   mutationQueueStarted,
                   syncStarted,
                   cleanedUpForTermination,
                   forceStopToStopSyncEngine,
                   completionBlockCalled,
                   forceStartToRestartSyncEngine
                  ], timeout: defaultAsyncWaitTimeout)

        remoteSyncEngineSink.cancel()
    }

    func testStopAndStartRemoteSync() throws {
        let stopSuccessful = expectation(description: "Stop Successful")
        let stopCompletionBlockCalled = expectation(description: "Completion block is called")
        let startCalledToRestartSyncEngine = expectation(description: "Start after Stop is Called now")

        var currCount = 1

        let advice = RequestRetryAdvice.init(shouldRetry: false)
        mockRequestRetryablePolicy.pushOnRetryRequestAdvice(response: advice)

        let stopRemoteSyncEngineSink = remoteSyncEngine
            .publisher
            .sink(receiveCompletion: { _ in
                print("Stop successful")
                currCount = self.checkAndFulfill(currCount, 1, expectation: stopSuccessful)
            }, receiveValue: { result in
                if case .cleanedUpForTermination = result {
                    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
                        print("calling start..")
                        self.remoteSyncEngine.start(api: self.apiPlugin)
                        // [placeholder] check the State of RemoteSync Engine here to verify if it started
                        currCount = self.checkAndFulfill(currCount, 3, expectation: startCalledToRestartSyncEngine)
                    }
                }
            })
        remoteSyncEngine.stop(completion: { result in
            if case .success = result {
                print("Stop Completion block called")
                currCount = self.checkAndFulfill(currCount, 2, expectation: stopCompletionBlockCalled)
            }

        })

        wait(for: [stopSuccessful, stopCompletionBlockCalled, startCalledToRestartSyncEngine], timeout: defaultAsyncWaitTimeout)

        //stopped again to avoid flakyness
        remoteSyncEngine.stop(completion: { _ in
            print("Stopped again after - Stop - Start" )
        })

        stopRemoteSyncEngineSink.cancel()
    }

    func testStopStopAndStartRemoteSyncEngine() {
        let stopSuccessful = expectation(description: "Stop Successful")
        let stopCompletionBlockCalled = expectation(description: "Completion block is called")
        let secondStopcalledToStopSyncEngine = expectation(description: "Stop after Stop is Called now")

        var currStopCount = 1

        let advice = RequestRetryAdvice.init(shouldRetry: false)
        mockRequestRetryablePolicy.pushOnRetryRequestAdvice(response: advice)

        let stopRemoteSyncEngineSink = remoteSyncEngine
            .publisher
            .sink(receiveCompletion: { _ in
                print("Stop successful")
                currStopCount = self.checkAndFulfill(currStopCount, 1, expectation: stopSuccessful)
            }, receiveValue: { result in
                if case .cleanedUpForTermination = result {
                    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
                        self.remoteSyncEngine.stop(completion: { result in
                            if case .success = result {
                                currStopCount = self.checkAndFulfill(currStopCount, 3, expectation: secondStopcalledToStopSyncEngine)
                            }
                        })
                    }
                }
            })
        remoteSyncEngine.stop(completion: { result in
            if case .success = result {
                print("Stop Completion block called")
                currStopCount = self.checkAndFulfill(currStopCount, 2, expectation: stopCompletionBlockCalled)
            }

        })

        wait(for: [stopSuccessful, stopCompletionBlockCalled, secondStopcalledToStopSyncEngine], timeout: defaultAsyncWaitTimeout)
        stopRemoteSyncEngineSink.cancel()

        remoteSyncEngine.start(api: apiPlugin)
        //[placeholder] check the State of RemoteSync Engine here to verify if it started
    }

    private func checkAndFulfill(_ currCount: Int, _ expectedCount: Int, expectation: XCTestExpectation) -> Int {
        if currCount == expectedCount {
            expectation.fulfill()
            return currCount + 1
        }
        return currCount
    }
}
