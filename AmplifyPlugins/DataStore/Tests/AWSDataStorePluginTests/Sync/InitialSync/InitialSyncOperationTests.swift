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
@testable import AWSDataStorePlugin
@testable import AWSPluginsCore

// swiftlint:disable type_body_length
class InitialSyncOperationTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
        ModelRegistry.register(modelType: MockSynced.self)
    }

    // MARK: - GetLastSyncTime

    func testFullSyncWhenLastSyncPredicateNilAndCurrentSyncPredicateNonNil() async {
        let lastSyncTime: Int64 = 123456
        let lastSyncPredicate: String? = nil
        let currentSyncPredicate: DataStoreConfiguration
        #if os(watchOS)
        currentSyncPredicate = DataStoreConfiguration.custom(
            syncExpressions: [
                .syncExpression(
                    MockSynced.schema,
                    where: { MockSynced.keys.id.eq("123") }
                )
            ],
            disableSubscriptions: { false }
        )
        #else
        currentSyncPredicate = DataStoreConfiguration.custom(
            syncExpressions: [
                .syncExpression(
                    MockSynced.schema,
                    where: { MockSynced.keys.id.eq("123") }
                )
            ]
        )
        #endif

        let expectedSyncType = SyncType.fullSync
        let expectedLastSync: Int64? = nil

        let syncStartedReceived = expectation(description: "Sync started received, sync operation started")
        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: nil,
            reconciliationQueue: nil,
            storageAdapter: nil,
            dataStoreConfiguration: currentSyncPredicate,
            authModeStrategy: AWSDefaultAuthModeStrategy())
        let sink = operation
            .publisher
            .sink(receiveCompletion: { _ in
            }, receiveValue: { value in
                switch value {
                case .started(modelName: let modelName, syncType: let syncType):
                    XCTAssertEqual(modelName, "MockSynced")
                    XCTAssertEqual(syncType, expectedSyncType)
                    syncStartedReceived.fulfill()
                default:
                    break
                }
            })

        let lastSyncMetadataLastSyncNil = ModelSyncMetadata(id: MockSynced.schema.name,
                                                            lastSync: lastSyncTime,
                                                            syncPredicate: lastSyncPredicate)
        XCTAssertEqual(operation.getLastSyncTime(lastSyncMetadataLastSyncNil), expectedLastSync)

        await fulfillment(of: [syncStartedReceived], timeout: 1)
        sink.cancel()
    }

    func testFullSyncWhenLastSyncPredicateNonNilAndCurrentSyncPredicateNil() async {
        let lastSyncTime: Int64 = 123456
        let lastSyncPredicate: String? = "non nil"
        let expectedSyncType = SyncType.fullSync
        let expectedLastSync: Int64? = nil

        let syncStartedReceived = expectation(description: "Sync started received, sync operation started")
        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: nil,
            reconciliationQueue: nil,
            storageAdapter: nil,
            dataStoreConfiguration: .testDefault(),
            authModeStrategy: AWSDefaultAuthModeStrategy())
        let sink = operation
            .publisher
            .sink(receiveCompletion: { _ in
            }, receiveValue: { value in
                switch value {
                case .started(modelName: let modelName, syncType: let syncType):
                    XCTAssertEqual(modelName, "MockSynced")
                    XCTAssertEqual(syncType, expectedSyncType)
                    syncStartedReceived.fulfill()
                default:
                    break
                }
            })

        let lastSyncMetadataLastSyncNil = ModelSyncMetadata(id: MockSynced.schema.name,
                                                            lastSync: lastSyncTime,
                                                            syncPredicate: lastSyncPredicate)
        XCTAssertEqual(operation.getLastSyncTime(lastSyncMetadataLastSyncNil), expectedLastSync)

        await fulfillment(of: [syncStartedReceived], timeout: 1)
        sink.cancel()
    }

    func testFullSyncWhenLastSyncPredicateDifferentFromCurrentSyncPredicate() async {
        let lastSyncTime: Int64 = 123456
        let lastSyncPredicate: String? = "non nil different from current predicate"
        let currentSyncPredicate: DataStoreConfiguration
        #if os(watchOS)
        currentSyncPredicate = DataStoreConfiguration.custom(
            syncExpressions: [
                .syncExpression(
                    MockSynced.schema,
                    where: { MockSynced.keys.id.eq("123") }
                )
            ],
            disableSubscriptions: { false }
        )
        #else
        currentSyncPredicate = DataStoreConfiguration.custom(
            syncExpressions: [
                .syncExpression(
                    MockSynced.schema,
                    where: { MockSynced.keys.id.eq("123") }
                )
            ]
        )
        #endif

        let expectedSyncType = SyncType.fullSync
        let expectedLastSync: Int64? = nil

        let syncStartedReceived = expectation(description: "Sync started received, sync operation started")
        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: nil,
            reconciliationQueue: nil,
            storageAdapter: nil,
            dataStoreConfiguration: currentSyncPredicate,
            authModeStrategy: AWSDefaultAuthModeStrategy())
        let sink = operation
            .publisher
            .sink(receiveCompletion: { _ in
            }, receiveValue: { value in
                switch value {
                case .started(modelName: let modelName, syncType: let syncType):
                    XCTAssertEqual(modelName, "MockSynced")
                    XCTAssertEqual(syncType, expectedSyncType)
                    syncStartedReceived.fulfill()
                default:
                    break
                }
            })

        let lastSyncMetadataLastSyncNil = ModelSyncMetadata(id: MockSynced.schema.name,
                                                            lastSync: lastSyncTime,
                                                            syncPredicate: lastSyncPredicate)
        XCTAssertEqual(operation.getLastSyncTime(lastSyncMetadataLastSyncNil), expectedLastSync)

        await fulfillment(of: [syncStartedReceived], timeout: 1)
        sink.cancel()
    }

    func testDeltaSyncWhenLastSyncPredicateSameAsCurrentSyncPredicate() async {
        let startDateSeconds = (Int64(Date().timeIntervalSince1970) - 100)
        let lastSyncTime: Int64 = startDateSeconds * 1_000
        let lastSyncPredicate: String? = "{\"field\":\"id\",\"operator\":{\"type\":\"equals\",\"value\":\"123\"}}"
        let currentSyncPredicate: DataStoreConfiguration
        #if os(watchOS)
        currentSyncPredicate = DataStoreConfiguration.custom(
            syncExpressions: [
                .syncExpression(
                    MockSynced.schema,
                    where: { MockSynced.keys.id.eq("123") }
                )
            ],
            disableSubscriptions: { false }
        )
        #else
        currentSyncPredicate = DataStoreConfiguration.custom(
            syncExpressions: [
                .syncExpression(
                    MockSynced.schema,
                    where: { MockSynced.keys.id.eq("123") }
                )
            ]
        )
        #endif

        let expectedSyncType = SyncType.deltaSync
        let expectedLastSync: Int64? = lastSyncTime

        let syncStartedReceived = expectation(description: "Sync started received, sync operation started")
        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: nil,
            reconciliationQueue: nil,
            storageAdapter: nil,
            dataStoreConfiguration: currentSyncPredicate,
            authModeStrategy: AWSDefaultAuthModeStrategy())
        let sink = operation
            .publisher
            .sink(receiveCompletion: { _ in
            }, receiveValue: { value in
                switch value {
                case .started(modelName: let modelName, syncType: let syncType):
                    XCTAssertEqual(modelName, "MockSynced")
                    XCTAssertEqual(syncType, expectedSyncType)
                    syncStartedReceived.fulfill()
                default:
                    break
                }
            })

        let lastSyncMetadataLastSyncNil = ModelSyncMetadata(id: MockSynced.schema.name,
                                                            lastSync: lastSyncTime,
                                                            syncPredicate: lastSyncPredicate)
        XCTAssertEqual(operation.getLastSyncTime(lastSyncMetadataLastSyncNil), expectedLastSync)

        await fulfillment(of: [syncStartedReceived], timeout: 1)
        sink.cancel()
    }

    // MARK: - `main()` tests

    /// - Given: An InitialSyncOperation
    /// - When:
    ///    - I invoke main()
    /// - Then:
    ///    - It reads sync metadata from storage
    func testReadsMetadata() async {
        let responder = QueryRequestResponder<PaginatedList<AnyModel>> { _ in
            let startDateMilliseconds = Int64(Date().timeIntervalSince1970) * 1_000
            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: startDateMilliseconds)
            return .success(list)
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestResponse] = responder

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
            dataStoreConfiguration: .testDefault(),
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

        await fulfillment(of: [syncStartedReceived, syncCompletionReceived, finishedReceived, metadataQueryReceived], timeout: 1)
        sink.cancel()
    }

    /// - Given: An InitialSyncOperation
    /// - When:
    ///    - I invoke main()
    /// - Then:
    ///    - It performs a sync query against the API category
    func testQueriesAPI() async {
        let apiWasQueried = expectation(description: "API was queried for a PaginatedList of AnyModel")
        let responder = QueryRequestResponder<PaginatedList<AnyModel>> { _ in
            let startDateMilliseconds = Int64(Date().timeIntervalSince1970) * 1_000
            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: startDateMilliseconds)
            apiWasQueried.fulfill()
            return .success(list)
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestResponse] = responder

        let storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.returnOnQueryModelSyncMetadata(nil)

        let reconciliationQueue = MockReconciliationQueue()
        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: apiPlugin,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter,
            dataStoreConfiguration: .testDefault(),
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

        await fulfillment(of: [syncStartedReceived, syncCompletionReceived, finishedReceived, apiWasQueried], timeout: 1)
        sink.cancel()
    }

    /// - Given: An InitialSyncOperation
    /// - When:
    ///    - I invoke main()
    /// - Then:
    ///    - The method invokes a completion callback when complete
    func testInvokesPublisherCompletion() async {
        let responder = QueryRequestResponder<PaginatedList<AnyModel>> { _ in
            let startDateMilliseconds = Int64(Date().timeIntervalSince1970) * 1_000
            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: startDateMilliseconds)
            return .success(list)
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestResponse] = responder

        let storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.returnOnQueryModelSyncMetadata(nil)

        let reconciliationQueue = MockReconciliationQueue()
        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: apiPlugin,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter,
            dataStoreConfiguration: .testDefault(),
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

        await fulfillment(of: [syncCompletionReceived, finishedReceived], timeout: 1)
        sink.cancel()
    }

    /// - Given: An InitialSyncOperation
    /// - When:
    ///    - I invoke main() against an API that returns paginated data
    /// - Then:
    ///    - The method invokes a completion callback
    func testRetrievesPaginatedData() async {
        let apiWasQueried = expectation(description: "API was queried for a PaginatedList of AnyModel")
        apiWasQueried.expectedFulfillmentCount = 3

        var nextTokens = ["token1", "token2"]

        let responder = QueryRequestResponder<PaginatedList<AnyModel>> { _ in
            let startedAt = Int64(Date().timeIntervalSince1970)
            let nextToken = nextTokens.isEmpty ? nil : nextTokens.removeFirst()
            let list = PaginatedList<AnyModel>(items: [], nextToken: nextToken, startedAt: startedAt)
            apiWasQueried.fulfill()
            return .success(list)
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestResponse] = responder

        let storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.returnOnQueryModelSyncMetadata(nil)

        let reconciliationQueue = MockReconciliationQueue()
        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: apiPlugin,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter,
            dataStoreConfiguration: .testDefault(),
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

        await fulfillment(of: [syncCompletionReceived, finishedReceived, apiWasQueried], timeout: 1)
        sink.cancel()
    }

    /// - Given: An InitialSyncOperation
    /// - When:
    ///    - I invoke main() against an API that returns data
    /// - Then:
    ///    - The method submits the returned data to the reconciliation queue
    func testSubmitsToReconciliationQueue() async {
        let startedAtMilliseconds = Int64(Date().timeIntervalSince1970) * 1_000
        let model = MockSynced(id: "1")
        let anyModel = AnyModel(model)
        let metadata = MutationSyncMetadata(modelId: "1",
                                            modelName: MockSynced.modelName,
                                            deleted: false,
                                            lastChangedAt: Int64(Date().timeIntervalSince1970),
                                            version: 1)
        let mutationSync = MutationSync(model: anyModel, syncMetadata: metadata)
        let responder = QueryRequestResponder<PaginatedList<AnyModel>> { _ in
            let list = PaginatedList<AnyModel>(items: [mutationSync], nextToken: nil, startedAt: startedAtMilliseconds)
            return .success(list)
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestResponse] = responder

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
            dataStoreConfiguration: .testDefault(),
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

        await fulfillment(of: [syncStartedReceived, syncCompletionReceived, finishedReceived, itemSubmitted, offeredValueReceived], timeout: 1)
        sink.cancel()
    }

    /// - Given: An InitialSyncOperation
    /// - When:
    ///    - I invoke main() against an API that returns data
    /// - Then:
    ///    - The method submits the returned data to the reconciliation queue
    func testUpdatesSyncMetadata() async throws {
        let startDateMilliseconds = Int64(Date().timeIntervalSince1970) * 1_000
        let responder = QueryRequestResponder<PaginatedList<AnyModel>> { _ in
            let startedAt = startDateMilliseconds
            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: startedAt)
            return .success(list)
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestResponse] = responder

        let storageAdapter = try SQLiteStorageEngineAdapter(connection: Connection(.inMemory))
        try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas + [MockSynced.schema])

        let reconciliationQueue = MockReconciliationQueue()
        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: apiPlugin,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter,
            dataStoreConfiguration: .testDefault(),
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

        await fulfillment(of: [syncStartedReceived, syncCompletionReceived, finishedReceived], timeout: 1)
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
    func testQueriesAPIReturnSignedOutError() async throws {
        let responder = QueryRequestResponder<PaginatedList<AnyModel>> { _ in
            let authError = AuthError.signedOut("", "", nil)
            let apiError = APIError.operationError("", "", authError)
            throw apiError
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestResponse] = responder

        let storageAdapter = try SQLiteStorageEngineAdapter(connection: Connection(.inMemory))

        let reconciliationQueue = MockReconciliationQueue()
        let expectErrorHandlerCalled = expectation(description: "Expect error handler called")

        #if os(watchOS)
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
        }, disableSubscriptions: { false })
        #else
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
        #endif
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

        await fulfillment(of: [
            expectErrorHandlerCalled,
            syncStartedReceived,
            syncCompletionReceived,
            finishedReceived
        ], timeout: 1)

        sink.cancel()
    }

    /// - Given: An InitialSyncOperation in a system with previous sync metadata
    /// - When:
    ///    - I invoke main()
    /// - Then:
    ///    - It performs a sync query against the API category with a "lastSync" time from the last start time of
    ///      the stored metadata
    func testQueriesFromLastSync() async throws {
        let startDateMilliseconds = (Int64(Date().timeIntervalSince1970) - 100) * 1_000

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
        await fulfillment(of: [syncMetadataSaved], timeout: 1)

        let apiWasQueried = expectation(description: "API was queried for a PaginatedList of AnyModel")
        let responder = QueryRequestResponder<PaginatedList<AnyModel>> { request in
            let lastSync = request.variables?["lastSync"] as? Int64
            XCTAssertEqual(lastSync, startDateMilliseconds)

            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: nil)
            apiWasQueried.fulfill()
            return .success(list)
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestResponse] = responder

        let reconciliationQueue = MockReconciliationQueue()
        let operation = InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: apiPlugin,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter,
            dataStoreConfiguration: .testDefault(),
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

        await fulfillment(of: [syncStartedReceived, syncCompletionReceived, finishedReceived, apiWasQueried], timeout: 1)
        sink.cancel()
    }

    func testBaseQueryWhenExpiredLastSync() async throws {
        // Set start date to 100 seconds in the past
        let startDateMilliSeconds = (Int64(Date().timeIntervalSince1970) - 100) * 1_000

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
        let responder = QueryRequestResponder<PaginatedList<AnyModel>> { request in
            let lastSync = request.variables?["lastSync"] as? Int
            XCTAssertNil(lastSync)

            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: nil)
            apiWasQueried.fulfill()
            return .success(list)
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestResponse] = responder

        let reconciliationQueue = MockReconciliationQueue()
        #if os(watchOS)
        let configuration  = DataStoreConfiguration.custom(syncInterval: 60, disableSubscriptions: { false })
        #else
        let configuration  = DataStoreConfiguration.custom(syncInterval: 60)
        #endif
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

        await fulfillment(of: [syncStartedReceived, syncCompletionReceived, finishedReceived, apiWasQueried], timeout: 1)
        sink.cancel()
    }

    func testBaseQueryWithCustomSyncPageSize() async throws {
        let storageAdapter = try SQLiteStorageEngineAdapter(connection: Connection(.inMemory))
        try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas + [MockSynced.schema])

        let apiWasQueried = expectation(description: "API was queried for a PaginatedList of AnyModel")
        let responder = QueryRequestResponder<PaginatedList<AnyModel>> { request in
            let lastSync = request.variables?["lastSync"] as? Int
            XCTAssertNil(lastSync)
            XCTAssert(request.document.contains("limit: Int"))
            let limitValue = request.variables?["limit"] as? Int
            XCTAssertEqual(10, limitValue)

            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: nil)
            apiWasQueried.fulfill()
            return .success(list)
        }

        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestResponse] = responder

        let reconciliationQueue = MockReconciliationQueue()
        #if os(watchOS)
        let configuration  = DataStoreConfiguration.custom(syncPageSize: 10, disableSubscriptions: { false })
        #else
        let configuration  = DataStoreConfiguration.custom(syncPageSize: 10)
        #endif
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

        await fulfillment(of: [
            syncStartedReceived,
            syncCompletionReceived,
            finishedReceived,
            apiWasQueried],
                          timeout: 1)
        sink.cancel()
    }
}
