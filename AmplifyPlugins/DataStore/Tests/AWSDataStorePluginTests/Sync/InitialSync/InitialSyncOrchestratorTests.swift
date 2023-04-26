//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin
@testable import AWSPluginsCore

class InitialSyncOrchestratorTests: XCTestCase {

    override class func setUp() {
        Amplify.Logging.logLevel = .info
    }

    /// - Given: An InitialSyncOrchestrator with a model dependency graph
    /// - When:
    ///    - The orchestrator starts up
    /// - Then:
    ///    - It performs a sync query for each registered model
    func testInvokesCompletionCallback() async throws {
        ModelRegistry.reset()
        PostCommentModelRegistration().registerModels(registry: ModelRegistry.self)
        let responder: QueryRequestListenerResponder<PaginatedList<AnyModel>> = { _, listener in
            let startedAt = Int(Date().timeIntervalSince1970)
            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: startedAt)
            let event: GraphQLOperation<PaginatedList<AnyModel>>.OperationResult = .success(.success(list))
            listener?(event)
            return nil
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestListener] = responder

        let storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.returnOnQueryModelSyncMetadata(nil)

        let reconciliationQueue = MockReconciliationQueue()

        let orchestrator: AWSInitialSyncOrchestrator =
        AWSInitialSyncOrchestrator(dataStoreConfiguration: .default,
                                   authModeStrategy: AWSDefaultAuthModeStrategy(),
                                   api: apiPlugin,
                                   reconciliationQueue: reconciliationQueue,
                                   storageAdapter: storageAdapter)

        let syncCallbackReceived = expectation(description: "Sync callback received, sync operation is complete")
        let syncQueriesStartedReceived = expectation(description: "syncQueriesStarted received")

        let filter = HubFilters.forEventName(HubPayload.EventName.DataStore.syncQueriesStarted)
        let hubListener = Amplify.Hub.listen(to: .dataStore, isIncluded: filter) { payload in
            guard let syncQueriesStartedEvent = payload.data as? SyncQueriesStartedEvent else {
                XCTFail("Failed to cast payload data as SyncQueriesStartedEvent")
                return
            }
            XCTAssertEqual(syncQueriesStartedEvent.models.count, 2)
            syncQueriesStartedReceived.fulfill()
        }

        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        let syncStartedReceived = expectation(description: "Sync started received, sync operation started")
        syncStartedReceived.expectedFulfillmentCount = 2
        let finishedReceived = expectation(description: "InitialSyncOperation finished paginating and offering")
        finishedReceived.expectedFulfillmentCount = 2
        let completionFinishedReceived = expectation(description: "InitialSyncOrchestrator finished successfully")
        let sink = orchestrator
            .publisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    completionFinishedReceived.fulfill()
                case .failure:
                    XCTFail("Should have completed with .finished")
                }
            }, receiveValue: { value in
                    switch value {
                    case .started:
                        syncStartedReceived.fulfill()
                    case .finished:
                        finishedReceived.fulfill()
                    default:
                        break
                    }
                  })

        orchestrator.sync { _ in
            syncCallbackReceived.fulfill()
        }

        await waitForExpectations(timeout: 1)
        XCTAssertEqual(orchestrator.syncOperationQueue.maxConcurrentOperationCount, 1)
        Amplify.Hub.removeListener(hubListener)
        sink.cancel()
    }

    /// - Given: An InitialSyncOrchestrator with a model dependency graph, API is expected to return an error for certain models
    /// - When:
    ///    - The orchestrator starts up
    /// - Then:
    ///    - Finish with an error for each sync query that fails.
    func testFinishWithAPIError() async throws {
        ModelRegistry.reset()
        PostCommentModelRegistration().registerModels(registry: ModelRegistry.self)
        let responder: QueryRequestListenerResponder<PaginatedList<AnyModel>> = { request, listener in
            if request.document.contains("SyncPosts") {
                let event: GraphQLOperation<PaginatedList<AnyModel>>.OperationResult =
                    .failure(APIError.operationError("", "", nil))
                listener?(event)
            } else if request.document.contains("SyncComments") {
                let startedAt = Int(Date().timeIntervalSince1970)
                let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: startedAt)
                let event: GraphQLOperation<PaginatedList<AnyModel>>.OperationResult = .success(.success(list))
                listener?(event)
            }

            return nil
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestListener] = responder

        let storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.returnOnQueryModelSyncMetadata(nil)

        let reconciliationQueue = MockReconciliationQueue()

        let orchestrator: AWSInitialSyncOrchestrator =
        AWSInitialSyncOrchestrator(dataStoreConfiguration: .default,
                                   authModeStrategy: AWSDefaultAuthModeStrategy(),
                                   api: apiPlugin,
                                   reconciliationQueue: reconciliationQueue,
                                   storageAdapter: storageAdapter)

        let syncCallbackReceived = expectation(description: "Sync callback received, sync operation is complete")
        let syncQueriesStartedReceived = expectation(description: "syncQueriesStarted received")

        let filter = HubFilters.forEventName(HubPayload.EventName.DataStore.syncQueriesStarted)
        let hubListener = Amplify.Hub.listen(to: .dataStore, isIncluded: filter) { payload in
            guard let syncQueriesStartedEvent = payload.data as? SyncQueriesStartedEvent else {
                XCTFail("Failed to cast payload data as SyncQueriesStartedEvent")
                return
            }
            XCTAssertEqual(syncQueriesStartedEvent.models.count, 2)
            syncQueriesStartedReceived.fulfill()
        }

        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        let syncStartedReceived = expectation(description: "Sync started received, sync operation started")
        syncStartedReceived.expectedFulfillmentCount = 2
        let finishedReceived = expectation(description: "InitialSyncOperation finished paginating and offering")
        finishedReceived.expectedFulfillmentCount = 2
        let failureCompletionReceived = expectation(description: "InitialSyncOrchestrator completed with failure")
        let sink = orchestrator
            .publisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail("Should have finished with failure")
                case .failure:
                    failureCompletionReceived.fulfill()
                }
            }, receiveValue: { value in
                switch value {
                case .started:
                    syncStartedReceived.fulfill()
                case .finished(let modelName, let error):
                    if modelName == "Post" {
                        guard case .api(let apiError, _) = error, case .operationError = apiError as? APIError else {
                            XCTFail("Should be api error")
                            return
                        }
                    } else if modelName == "Comment" {
                        XCTAssertNil(error)
                    }
                    finishedReceived.fulfill()
                default:
                    break
                }
            })

        orchestrator.sync { _ in
            syncCallbackReceived.fulfill()
        }

        await waitForExpectations(timeout: 1)
        XCTAssertEqual(orchestrator.syncOperationQueue.maxConcurrentOperationCount, 1)
        Amplify.Hub.removeListener(hubListener)
        sink.cancel()
    }

    /// - Given: An InitialSyncOrchestrator with a model dependency graph containing no associations
    /// - When:
    ///    - The orchestrator starts up
    /// - Then:
    ///    - It performs a sync query for each registered model with concurrency set to count of models
    func testInvokesCompletionCallback_ModelWithNoAssociations() throws {
        ModelRegistry.reset()
        struct TestModelsWithNoAssociations: AmplifyModelRegistration {
            func registerModels(registry: ModelRegistry.Type) {
                // Models without no associations
                registry.register(modelType: MockSynced.self)
                registry.register(modelType: ExampleWithEveryType.self)
            }

            let version: String = "1"
        }
        TestModelsWithNoAssociations().registerModels(registry: ModelRegistry.self)

        let responder: QueryRequestListenerResponder<PaginatedList<AnyModel>> =  { _, listener in
            let startedAt = Int(Date().timeIntervalSince1970)
            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: startedAt)
            let event: GraphQLOperation<PaginatedList<AnyModel>>.OperationResult = .success(.success(list))
            listener?(event)
            return nil
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestListener] = responder

        let storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.returnOnQueryModelSyncMetadata(nil)

        let reconciliationQueue = MockReconciliationQueue()

        let orchestrator = AWSInitialSyncOrchestrator(dataStoreConfiguration: .default,
                                                      authModeStrategy: AWSDefaultAuthModeStrategy(),
                                                      api: apiPlugin,
                                                      reconciliationQueue: reconciliationQueue,
                                                      storageAdapter: storageAdapter)
        let syncCallbackReceived = expectation(description: "Sync callback received, sync operation is complete")
        let syncStartedReceived = expectation(description: "Sync started received, sync operation started")
        syncStartedReceived.expectedFulfillmentCount = 2
        let finishedReceived = expectation(description: "InitialSyncOperation finished paginating and offering")
        finishedReceived.expectedFulfillmentCount = 2
        let sink = orchestrator
            .publisher
            .sink(receiveCompletion: { _ in },
                  receiveValue: { value in
                    switch value {
                    case .started:
                        syncStartedReceived.fulfill()
                    case .finished:
                        finishedReceived.fulfill()
                    default:
                        break
                    }
                  })

        orchestrator.sync { _ in
            syncCallbackReceived.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertEqual(orchestrator.syncOperationQueue.maxConcurrentOperationCount, 2)
        sink.cancel()
    }

    /// - Given: An InitialSyncOrchestrator with a model dependency graph
    /// - When:
    ///    - The orchestrator starts up
    /// - Then:
    ///    - It queries models in dependency order, from "parent" to "child"
    func testShouldQueryModelsInDependencyOrder() {
        ModelRegistry.reset()
        PostCommentModelRegistration().registerModels(registry: ModelRegistry.self)
        let postWasQueried = expectation(description: "Post was queried")
        let commentWasQueried = expectation(description: "Comment was queried")
        let responder: QueryRequestListenerResponder<PaginatedList<AnyModel>> = { request, listener in
            if request.document.hasPrefix("query SyncPosts") {
                postWasQueried.fulfill()
            }

            if request.document.hasPrefix("query SyncComments") {
                commentWasQueried.fulfill()
            }

            let startedAt = Int(Date().timeIntervalSince1970)
            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: startedAt)
            let event: GraphQLOperation<PaginatedList<AnyModel>>.OperationResult = .success(.success(list))
            listener?(event)
            return nil
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestListener] = responder

        let storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.returnOnQueryModelSyncMetadata(nil)

        let reconciliationQueue = MockReconciliationQueue()

        let orchestrator: AWSInitialSyncOrchestrator =
            AWSInitialSyncOrchestrator(dataStoreConfiguration: .default,
                                       authModeStrategy: AWSDefaultAuthModeStrategy(),
                                       api: apiPlugin,
                                       reconciliationQueue: reconciliationQueue,
                                       storageAdapter: storageAdapter)

        let syncStartedReceived = expectation(description: "Sync started received, sync operation started")
        syncStartedReceived.expectedFulfillmentCount = 2
        let finishedReceived = expectation(description: "InitialSyncOperation finished paginating and offering")
        finishedReceived.expectedFulfillmentCount = 2
        let sink = orchestrator
            .publisher
            .sink(receiveCompletion: { _ in },
                  receiveValue: { value in
                    switch value {
                    case .started:
                        syncStartedReceived.fulfill()
                    case .finished:
                        finishedReceived.fulfill()
                    default:
                        break
                    }
                  })

        orchestrator.sync { _ in }

        waitForExpectations(timeout: 1)
        XCTAssertEqual(orchestrator.syncOperationQueue.maxConcurrentOperationCount, 1)
        sink.cancel()
    }

    /// - Given: An InitialSyncOrchestrator with a model dependency graph
    /// - When:
    ///    - The orchestrator starts up
    /// - Then:
    ///    - It queries models in dependency order, from "parent" to "child", even if parent data is returned in
    ///      multiple pages
    func testShouldQueryModelsInDependencyOrderWithPaginatedResults() {
        ModelRegistry.reset()
        PostCommentModelRegistration().registerModels(registry: ModelRegistry.self)
        let pageCount = 50

        let postWasQueried = expectation(description: "Post was queried")
        postWasQueried.expectedFulfillmentCount = pageCount

        let commentWasQueried = expectation(description: "Comment was queried")

        var nextTokens = Array(repeating: "token", count: pageCount - 1)

        let responder: QueryRequestListenerResponder<PaginatedList<AnyModel>> = { request, listener in
            if request.document.hasPrefix("query SyncPosts") {
                postWasQueried.fulfill()
            }

            if request.document.hasPrefix("query SyncComments") {
                commentWasQueried.fulfill()
            }

            let startedAt = Int(Date().timeIntervalSince1970)
            let nextToken = nextTokens.isEmpty ? nil : nextTokens.removeFirst()
            let list = PaginatedList<AnyModel>(items: [], nextToken: nextToken, startedAt: startedAt)
            let event: GraphQLOperation<PaginatedList<AnyModel>>.OperationResult = .success(.success(list))
            listener?(event)
            return nil
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestListener] = responder

        let storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.returnOnQueryModelSyncMetadata(nil)

        let reconciliationQueue = MockReconciliationQueue()

        let orchestrator: AWSInitialSyncOrchestrator =
            AWSInitialSyncOrchestrator(dataStoreConfiguration: .default,
                                       authModeStrategy: AWSDefaultAuthModeStrategy(),
                                       api: apiPlugin,
                                       reconciliationQueue: reconciliationQueue,
                                       storageAdapter: storageAdapter)

        let syncStartedReceived = expectation(description: "Sync started received, sync operation started")
        syncStartedReceived.expectedFulfillmentCount = 2
        let finishedReceived = expectation(description: "InitialSyncOperation finished paginating and offering")
        finishedReceived.expectedFulfillmentCount = 2
        let sink = orchestrator
            .publisher
            .sink(receiveCompletion: { _ in },
                  receiveValue: { value in
                    switch value {
                    case .started:
                        syncStartedReceived.fulfill()
                    case .finished:
                        finishedReceived.fulfill()
                    default:
                        break
                    }
                  })

        orchestrator.sync { _ in }

        waitForExpectations(timeout: 1)
        XCTAssertEqual(orchestrator.syncOperationQueue.maxConcurrentOperationCount, 1)
        sink.cancel()
    }

}
