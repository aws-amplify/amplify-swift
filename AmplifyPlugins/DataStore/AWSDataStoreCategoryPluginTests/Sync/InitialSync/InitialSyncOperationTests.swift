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
@testable import AWSPluginsCore

// swiftlint:disable type_body_length
class InitialSyncOperationTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
        ModelRegistry.register(modelType: MockSynced.self)
    }

    /// - Given: An InitialSyncOperation
    /// - When:
    ///    - I invoke main()
    /// - Then:
    ///    - It reads sync metadata from storage
    func testReadsMetadata() {
        let responder = QueryRequestListenerResponder<PaginatedList<AnyModel>> { _, listener in
            let startDateMilliseconds = Int(Date().timeIntervalSince1970) * 1_000
            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: startDateMilliseconds)
            let event: GraphQLOperation<PaginatedList<AnyModel>>.OperationResult = .success(.success(list))
            listener?(event)
            return nil
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestListener] = responder

        let storageAdapter = MockSQLiteStorageEngineAdapter()
        let metadataQueryReceived = expectation(description: "Metadata query received by storage adapter")
        storageAdapter.returnOnQueryModelSyncMetadata(nil) {
            metadataQueryReceived.fulfill()
        }

        let reconciliationQueue = MockReconciliationQueue()
        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: apiPlugin,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter,
            dataStoreConfiguration: .default,
            authModeStrategy: AWSDefaultAuthModeStrategy())

        let syncStartedReceived = expectation(description: "Sync started received, sync operation started")
        let syncCompletionReceived = expectation(description: "Sync completion received, sync operation is complete")
        let finishedReceived = expectation(description: "InitialSyncOperation finishe offering items")
        let sink = operation
            .publisher
            .sink(receiveCompletion: { _ in
                syncCompletionReceived.fulfill()
            }, receiveValue: { value in
                switch value {
                case .started(modelName: let modelName, syncType: let syncType):
                    XCTAssertEqual(modelName, "MockSynced")
                    XCTAssertEqual(syncType, .fullSync)
                    syncStartedReceived.fulfill()
                case .finished(modelName: let modelName, error: let error):
                    XCTAssertNil(error)
                    XCTAssertEqual(modelName, "MockSynced")
                    finishedReceived.fulfill()
                default:
                    break
                }
            })

        operation.main()

        waitForExpectations(timeout: 1)
        sink.cancel()
    }

    /// - Given: An InitialSyncOperation
    /// - When:
    ///    - I invoke main()
    /// - Then:
    ///    - It performs a sync query against the API category
    func testQueriesAPI() {
        let apiWasQueried = expectation(description: "API was queried for a PaginatedList of AnyModel")
        let responder = QueryRequestListenerResponder<PaginatedList<AnyModel>> { _, listener in
            let startDateMilliseconds = Int(Date().timeIntervalSince1970) * 1_000
            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: startDateMilliseconds)
            let event: GraphQLOperation<PaginatedList<AnyModel>>.OperationResult = .success(.success(list))
            listener?(event)
            apiWasQueried.fulfill()
            return nil
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestListener] = responder

        let storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.returnOnQueryModelSyncMetadata(nil)

        let reconciliationQueue = MockReconciliationQueue()
        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: apiPlugin,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter,
            dataStoreConfiguration: .default,
            authModeStrategy: AWSDefaultAuthModeStrategy())

        let syncStartedReceived = expectation(description: "Sync started received, sync operation started")
        let syncCompletionReceived = expectation(description: "Sync completion received, sync operation is complete")
        let finishedReceived = expectation(description: "InitialSyncOperation finishe offering items")
        let sink = operation
            .publisher
            .sink(receiveCompletion: { _ in
                syncCompletionReceived.fulfill()
            }, receiveValue: { value in
                switch value {
                case .started(modelName: let modelName, syncType: let syncType):
                    XCTAssertEqual(modelName, "MockSynced")
                    XCTAssertEqual(syncType, .fullSync)
                    syncStartedReceived.fulfill()
                case .finished(modelName: let modelName, error: let error):
                    XCTAssertNil(error)
                    XCTAssertEqual(modelName, "MockSynced")
                    finishedReceived.fulfill()
                default:
                    break
                }
            })

        operation.main()

        waitForExpectations(timeout: 1)
        sink.cancel()
    }

    /// - Given: An InitialSyncOperation
    /// - When:
    ///    - I invoke main()
    /// - Then:
    ///    - The method invokes a completion callback when complete
    func testInvokesPublisherCompletion() {
        let responder = QueryRequestListenerResponder<PaginatedList<AnyModel>> { _, listener in
            let startDateMilliseconds = Int(Date().timeIntervalSince1970) * 1_000
            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: startDateMilliseconds)
            let event: GraphQLOperation<PaginatedList<AnyModel>>.OperationResult = .success(.success(list))
            listener?(event)
            return nil
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestListener] = responder

        let storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.returnOnQueryModelSyncMetadata(nil)

        let reconciliationQueue = MockReconciliationQueue()
        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: apiPlugin,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter,
            dataStoreConfiguration: .default,
            authModeStrategy: AWSDefaultAuthModeStrategy())

        let syncCompletionReceived = expectation(description: "Sync completion received, sync operation is complete")
        let finishedReceived = expectation(description: "InitialSyncOperation finished paginating and offering")
        let sink = operation.publisher.sink(receiveCompletion: { _ in
            syncCompletionReceived.fulfill()
        }, receiveValue: { value in
            switch value {
            case .finished(modelName: let modelName, error: let error):
                XCTAssertNil(error)
                XCTAssertEqual(modelName, "MockSynced")
                finishedReceived.fulfill()
            default:
                break
            }
        })

        operation.main()

        wait(for: [syncCompletionReceived, finishedReceived], timeout: 1.0)
        sink.cancel()
    }

    /// - Given: An InitialSyncOperation
    /// - When:
    ///    - I invoke main() against an API that returns paginated data
    /// - Then:
    ///    - The method invokes a completion callback
    func testRetrievesPaginatedData() {
        let apiWasQueried = expectation(description: "API was queried for a PaginatedList of AnyModel")
        apiWasQueried.expectedFulfillmentCount = 3

        var nextTokens = ["token1", "token2"]

        let responder = QueryRequestListenerResponder<PaginatedList<AnyModel>> { _, listener in
            let startedAt = Int(Date().timeIntervalSince1970)
            let nextToken = nextTokens.isEmpty ? nil : nextTokens.removeFirst()
            let list = PaginatedList<AnyModel>(items: [], nextToken: nextToken, startedAt: startedAt)
            let event: GraphQLOperation<PaginatedList<AnyModel>>.OperationResult = .success(.success(list))
            listener?(event)
            apiWasQueried.fulfill()
            return nil
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestListener] = responder

        let storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.returnOnQueryModelSyncMetadata(nil)

        let reconciliationQueue = MockReconciliationQueue()
        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: apiPlugin,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter,
            dataStoreConfiguration: .default,
            authModeStrategy: AWSDefaultAuthModeStrategy())

        let syncCompletionReceived = expectation(description: "Sync completion received, sync operation is complete")
        let finishedReceived = expectation(description: "InitialSyncOperation finished paginating and offering")
        let sink = operation.publisher.sink(receiveCompletion: { _ in
            syncCompletionReceived.fulfill()
        }, receiveValue: { value in
            switch value {
            case .finished(modelName: let modelName, error: let error):
                XCTAssertNil(error)
                XCTAssertEqual(modelName, "MockSynced")
                finishedReceived.fulfill()
            default:
                break
            }
        })

        operation.main()

        waitForExpectations(timeout: 1)
        sink.cancel()
    }

    /// - Given: An InitialSyncOperation
    /// - When:
    ///    - I invoke main() against an API that returns data
    /// - Then:
    ///    - The method submits the returned data to the reconciliation queue
    func testSubmitsToReconciliationQueue() {
        let startedAtMilliseconds = Int(Date().timeIntervalSince1970) * 1_000
        let model = MockSynced(id: "1")
        let anyModel = AnyModel(model)
        let metadata = MutationSyncMetadata(modelId: "1",
                                            modelName: MockSynced.modelName,
                                            deleted: false,
                                            lastChangedAt: Int(Date().timeIntervalSince1970),
                                            version: 1)
        let mutationSync = MutationSync(model: anyModel, syncMetadata: metadata)
        let responder = QueryRequestListenerResponder<PaginatedList<AnyModel>> { _, listener in
            let list = PaginatedList<AnyModel>(items: [mutationSync], nextToken: nil, startedAt: startedAtMilliseconds)
            let event: GraphQLOperation<PaginatedList<AnyModel>>.OperationResult = .success(.success(list))
            listener?(event)
            return nil
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestListener] = responder

        let storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.returnOnQueryModelSyncMetadata(nil)

        let itemSubmitted = expectation(description: "Item submitted to reconciliation queue")
        let reconciliationQueue = MockReconciliationQueue()
        reconciliationQueue.listeners.append { message in
            if message.hasPrefix("offer(_:)")
                && message.contains("MutationSync<AWSPluginsCore.AnyModel>")
                && message.contains(#"id: "1"#) {
                itemSubmitted.fulfill()
            }
        }

        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: apiPlugin,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter,
            dataStoreConfiguration: .default,
            authModeStrategy: AWSDefaultAuthModeStrategy())

        let syncStartedReceived = expectation(description: "Sync started received, sync operation started")
        let syncCompletionReceived = expectation(description: "Sync completion received, sync operation is complete")
        let offeredValueReceived = expectation(description: "mutationSync received, item is offered")
        let finishedReceived = expectation(description: "InitialSyncOperation finished paginating and offering")
        let sink = operation
            .publisher
            .sink(receiveCompletion: { _ in
                syncCompletionReceived.fulfill()
            }, receiveValue: { value in
                switch value {
                case .started(modelName: let modelName, syncType: let syncType):
                    XCTAssertEqual(modelName, "MockSynced")
                    XCTAssertEqual(syncType, .fullSync)
                    syncStartedReceived.fulfill()
                case .enqueued(let returnedValue, let modelName):
                    XCTAssertTrue(returnedValue.syncMetadata == mutationSync.syncMetadata)
                    XCTAssertEqual(modelName, "MockSynced")
                    offeredValueReceived.fulfill()
                case .finished(modelName: let modelName, error: let error):
                    XCTAssertNil(error)
                    XCTAssertEqual(modelName, "MockSynced")
                    finishedReceived.fulfill()
                }
            })

        operation.main()

        waitForExpectations(timeout: 1)
        sink.cancel()
    }

    /// - Given: An InitialSyncOperation
    /// - When:
    ///    - I invoke main() against an API that returns data
    /// - Then:
    ///    - The method submits the returned data to the reconciliation queue
    func testUpdatesSyncMetadata() throws {
        let startDateMilliseconds = Int(Date().timeIntervalSince1970) * 1_000
        let responder = QueryRequestListenerResponder<PaginatedList<AnyModel>> { _, listener in
            let startedAt = startDateMilliseconds
            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: startedAt)
            let event: GraphQLOperation<PaginatedList<AnyModel>>.OperationResult = .success(.success(list))
            listener?(event)
            return nil
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestListener] = responder

        let storageAdapter = try SQLiteStorageEngineAdapter(connection: Connection(.inMemory))
        try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas + [MockSynced.schema])

        let reconciliationQueue = MockReconciliationQueue()
        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: apiPlugin,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter,
            dataStoreConfiguration: .default,
            authModeStrategy: AWSDefaultAuthModeStrategy())

        let syncStartedReceived = expectation(description: "Sync started received, sync operation started")
        let syncCompletionReceived = expectation(description: "Sync completion received, sync operation is complete")
        let finishedReceived = expectation(description: "InitialSyncOperation finished paginating and offering")
        let sink = operation
            .publisher
            .sink(receiveCompletion: { _ in
                syncCompletionReceived.fulfill()
            }, receiveValue: { value in
                switch value {
                case .started(modelName: let modelName, syncType: let syncType):
                    XCTAssertEqual(modelName, "MockSynced")
                    XCTAssertEqual(syncType, .fullSync)
                    syncStartedReceived.fulfill()
                case .finished(modelName: let modelName, error: let error):
                    XCTAssertNil(error)
                    XCTAssertEqual(modelName, "MockSynced")
                    finishedReceived.fulfill()
                default:
                    break
                }
            })

        operation.main()

        waitForExpectations(timeout: 1)
        sink.cancel()

        guard let syncMetadata = try storageAdapter.queryModelSyncMetadata(for: MockSynced.schema) else {
            XCTFail("syncMetadata is nil")
            return
        }

        XCTAssertEqual(syncMetadata.lastSync, startDateMilliseconds)
    }

    /// - Given: An InitialSyncOperation
    /// - When:
    ///    - I invoke main() against an API that returns .signedOut error
    /// - Then:
    ///    - The method completes with a failure result, error handler is called.
    func testQueriesAPIReturnSignedOutError() throws {
        let responder = QueryRequestListenerResponder<PaginatedList<AnyModel>> { _, listener in
            let authError = AuthError.signedOut("", "", nil)
            let apiError = APIError.operationError("", "", authError)
            let event: GraphQLOperation<PaginatedList<AnyModel>>.OperationResult = .failure(apiError)
            listener?(event)
            return nil
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestListener] = responder

        let storageAdapter = try SQLiteStorageEngineAdapter(connection: Connection(.inMemory))

        let reconciliationQueue = MockReconciliationQueue()
        let expectErrorHandlerCalled = expectation(description: "Expect error handler called")
        let configuration = DataStoreConfiguration.custom(errorHandler: { error in
            guard let dataStoreError = error as? DataStoreError,
                case let .api(amplifyError, mutationEventOptional) = dataStoreError else {
                    XCTFail("Expected API error with mutationEvent")
                    return
            }
            guard let actualAPIError = amplifyError as? APIError,
                case let .operationError(_, _, underlyingError) = actualAPIError,
                let authError = underlyingError as? AuthError,
                case .signedOut = authError else {
                    XCTFail("Should be `signedOut` error but got \(amplifyError)")
                    return
            }
            expectErrorHandlerCalled.fulfill()
            XCTAssertNil(mutationEventOptional)
        })
        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: apiPlugin,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter,
            dataStoreConfiguration: configuration,
            authModeStrategy: AWSDefaultAuthModeStrategy())

        let syncStartedReceived = expectation(description: "Sync started received, sync operation started")
        let syncCompletionReceived = expectation(description: "Sync completion received, sync operation is complete")
        let finishedReceived = expectation(description: "InitialSyncOperation finished paginating and offering")
        let sink = operation.publisher.sink(receiveCompletion: { result in
            switch result {
            case .finished:
                XCTFail("Should have failed")
            case .failure:
                syncCompletionReceived.fulfill()
            }
        }, receiveValue: { value in
            switch value {
            case .started(modelName: let modelName, syncType: let syncType):
                XCTAssertEqual(modelName, "MockSynced")
                XCTAssertEqual(syncType, .fullSync)
                syncStartedReceived.fulfill()
            case .finished(modelName: let modelName, error: let error):
                guard case .api = error else {
                    XCTFail("Should be api error")
                    return
                }
                XCTAssertEqual(modelName, "MockSynced")
                finishedReceived.fulfill()
            default:
                break
            }
        })

        operation.main()

        waitForExpectations(timeout: 1)

        sink.cancel()
    }

    /// - Given: An InitialSyncOperation in a system with previous sync metadata
    /// - When:
    ///    - I invoke main()
    /// - Then:
    ///    - It performs a sync query against the API category with a "lastSync" time from the last start time of
    ///      the stored metadata
    func testQueriesFromLastSync() throws {
        let startDateMilliseconds = (Int(Date().timeIntervalSince1970) - 100) * 1_000

        let storageAdapter = try SQLiteStorageEngineAdapter(connection: Connection(.inMemory))
        try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas + [MockSynced.schema])

        let syncMetadata = ModelSyncMetadata(id: MockSynced.modelName, lastSync: startDateMilliseconds)
        let syncMetadataSaved = expectation(description: "Sync metadata saved")
        storageAdapter.save(syncMetadata) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success:
                syncMetadataSaved.fulfill()
            }
        }
        wait(for: [syncMetadataSaved], timeout: 1.0)

        let apiWasQueried = expectation(description: "API was queried for a PaginatedList of AnyModel")
        let responder = QueryRequestListenerResponder<PaginatedList<AnyModel>> { request, listener in
            let lastSync = request.variables?["lastSync"] as? Int
            XCTAssertEqual(lastSync, startDateMilliseconds)

            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: nil)
            let event: GraphQLOperation<PaginatedList<AnyModel>>.OperationResult = .success(.success(list))
            listener?(event)
            apiWasQueried.fulfill()
            return nil
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestListener] = responder

        let reconciliationQueue = MockReconciliationQueue()
        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: apiPlugin,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter,
            dataStoreConfiguration: .default,
            authModeStrategy: AWSDefaultAuthModeStrategy())

        let syncStartedReceived = expectation(description: "Sync started received, sync operation started")
        let syncCompletionReceived = expectation(description: "Sync completion received, sync operation is complete")
        let finishedReceived = expectation(description: "InitialSyncOperation finished paginating and offering")
        let sink = operation
            .publisher
            .sink(receiveCompletion: { _ in
                syncCompletionReceived.fulfill()
            }, receiveValue: { value in
                switch value {
                case .started(modelName: let modelName, syncType: let syncType):
                    XCTAssertEqual(modelName, "MockSynced")
                    XCTAssertEqual(syncType, .deltaSync)
                    syncStartedReceived.fulfill()
                case .finished(modelName: let modelName, error: let error):
                    XCTAssertNil(error)
                    XCTAssertEqual(modelName, "MockSynced")
                    finishedReceived.fulfill()
                default:
                    break
                }
            })

        operation.main()

        waitForExpectations(timeout: 1)
        sink.cancel()
    }

    func testBaseQueryWhenExpiredLastSync() throws {
        // Set start date to 100 seconds in the past
        let startDateMilliSeconds = (Int(Date().timeIntervalSince1970) - 100) * 1_000

        let storageAdapter = try SQLiteStorageEngineAdapter(connection: Connection(.inMemory))
        try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas + [MockSynced.schema])

        let syncMetadata = ModelSyncMetadata(id: MockSynced.modelName, lastSync: startDateMilliSeconds)
        let syncMetadataSaved = expectation(description: "Sync metadata saved")
        storageAdapter.save(syncMetadata) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success:
                syncMetadataSaved.fulfill()
            }
        }
        wait(for: [syncMetadataSaved], timeout: 1.0)

        let apiWasQueried = expectation(description: "API was queried for a PaginatedList of AnyModel")
        let responder = QueryRequestListenerResponder<PaginatedList<AnyModel>> { request, listener in
            let lastSync = request.variables?["lastSync"] as? Int
            XCTAssertNil(lastSync)

            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: nil)
            let event: GraphQLOperation<PaginatedList<AnyModel>>.OperationResult = .success(.success(list))
            listener?(event)
            apiWasQueried.fulfill()
            return nil
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestListener] = responder

        let reconciliationQueue = MockReconciliationQueue()
        let configuration  = DataStoreConfiguration.custom(syncInterval: 60)
        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: apiPlugin,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter,
            dataStoreConfiguration: configuration,
            authModeStrategy: AWSDefaultAuthModeStrategy())

        let syncStartedReceived = expectation(description: "Sync started received, sync operation started")
        let syncCompletionReceived = expectation(description: "Sync completion received, sync operation is complete")
        let finishedReceived = expectation(description: "InitialSyncOperation finished paginating and offering")
        let sink = operation
            .publisher
            .sink(receiveCompletion: { _ in
                syncCompletionReceived.fulfill()
            }, receiveValue: { value in
                switch value {
                case .started(modelName: let modelName, syncType: let syncType):
                    XCTAssertEqual(modelName, "MockSynced")
                    XCTAssertEqual(syncType, .fullSync)
                    syncStartedReceived.fulfill()
                case .finished(modelName: let modelName, error: let error):
                    XCTAssertNil(error)
                    XCTAssertEqual(modelName, "MockSynced")
                    finishedReceived.fulfill()
                default:
                    break
                }
            })

        operation.main()

        waitForExpectations(timeout: 1)
        sink.cancel()
    }

    func testBaseQueryWithCustomSyncPageSize() throws {
        let storageAdapter = try SQLiteStorageEngineAdapter(connection: Connection(.inMemory))
        try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas + [MockSynced.schema])

        let apiWasQueried = expectation(description: "API was queried for a PaginatedList of AnyModel")
        let responder = QueryRequestListenerResponder<PaginatedList<AnyModel>> { request, listener in
            let lastSync = request.variables?["lastSync"] as? Int
            XCTAssertNil(lastSync)
            XCTAssert(request.document.contains("limit: Int"))
            let limitValue = request.variables?["limit"] as? Int
            XCTAssertEqual(10, limitValue)

            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: nil)
            let event: GraphQLOperation<PaginatedList<AnyModel>>.OperationResult = .success(.success(list))
            listener?(event)
            apiWasQueried.fulfill()
            return nil
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestListener] = responder

        let reconciliationQueue = MockReconciliationQueue()
        let configuration  = DataStoreConfiguration.custom(syncPageSize: 10)
        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: apiPlugin,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter,
            dataStoreConfiguration: configuration,
            authModeStrategy: AWSDefaultAuthModeStrategy())

        let syncStartedReceived = expectation(description: "Sync started received, sync operation started")
        let syncCompletionReceived = expectation(description: "Sync completion received, sync operation is complete")
        let finishedReceived = expectation(description: "InitialSyncOperation finishe offering items")
        let sink = operation
            .publisher
            .sink(receiveCompletion: { _ in
                syncCompletionReceived.fulfill()
            }, receiveValue: { value in
                switch value {
                case .started(modelName: let modelName, syncType: let syncType):
                    XCTAssertEqual(modelName, "MockSynced")
                    XCTAssertEqual(syncType, .fullSync)
                    syncStartedReceived.fulfill()
                case .finished(modelName: let modelName, error: let error):
                    XCTAssertNil(error)
                    XCTAssertEqual(modelName, "MockSynced")
                    finishedReceived.fulfill()
                default:
                    break
                }
            })

        operation.main()

        waitForExpectations(timeout: 1)
        sink.cancel()
    }
} // swiftlint:disable:this file_length
