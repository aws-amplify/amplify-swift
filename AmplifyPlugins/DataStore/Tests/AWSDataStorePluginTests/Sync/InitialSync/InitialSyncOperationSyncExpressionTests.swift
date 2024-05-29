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

class InitialSyncOperationSyncExpressionTests: XCTestCase {
    typealias APIPluginQueryResponder = QueryRequestResponder<PaginatedList<AnyModel>>

    var storageAdapter: StorageEngineAdapter!
    var apiPlugin = MockAPICategoryPlugin()
    let reconciliationQueue = MockReconciliationQueue()
    var syncStartedReceived: XCTestExpectation!
    var syncCompletionReceived: XCTestExpectation!
    var finishedReceived: XCTestExpectation!
    var apiWasQueried: XCTestExpectation!

    override func setUpWithError() throws {
        storageAdapter = try SQLiteStorageEngineAdapter(connection: Connection(.inMemory))
        try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas + [MockSynced.schema])
        syncStartedReceived = expectation(description: "Sync started received, sync operation started")
        syncCompletionReceived = expectation(description: "Sync completion received, sync operation is complete")
        finishedReceived = expectation(description: "InitialSyncOperation finishe offering items")
        apiWasQueried = expectation(description: "API was queried with sync expression")
    }

    func initialSyncOperation(withSyncExpression syncExpression: DataStoreSyncExpression,
                              responder: APIPluginQueryResponder) -> InitialSyncOperation {
        apiPlugin.responders[.queryRequestResponse] = responder
        #if os(watchOS)
        let configuration  = DataStoreConfiguration.custom(syncPageSize: 10,
                                                           syncExpressions: [syncExpression],
                                                           disableSubscriptions: { false })
        #else
        let configuration  = DataStoreConfiguration.custom(syncPageSize: 10,
                                                           syncExpressions: [syncExpression])
        #endif
        return InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: apiPlugin,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter,
            dataStoreConfiguration: configuration,
            authModeStrategy: AWSDefaultAuthModeStrategy())
    }

    func testBaseQueryWithBasicSyncExpression() async throws {
        let responder = APIPluginQueryResponder { request in
            XCTAssertEqual(request.document, """
            query SyncMockSynceds($filter: ModelMockSyncedFilterInput, $limit: Int) {
              syncMockSynceds(filter: $filter, limit: $limit) {
                items {
                  id
                  __typename
                  _version
                  _deleted
                  _lastChangedAt
                }
                nextToken
                startedAt
              }
            }
            """)
            guard let filter = request.variables?["filter"] as? [String: Any?] else {
                XCTFail("Unable to get filter")
                return .failure(.unknown("Unable to get filter", "", nil))
            }
            guard let group = filter["and"] as? [[String: Any?]] else {
                XCTFail("Unable to find 'and' group")
                return .failure(.unknown("Unable to find 'and' group", "", nil))
            }

            guard let key = group[0]["id"] as? [String: Any?] else {
                XCTFail("Unable to get id from filter")
                return .failure(.unknown("Unable to get id from filter", "", nil))
            }
            guard let value = key["eq"] as? String else {
                XCTFail("Unable to get eq from key")
                return .failure(.unknown("Unable to get eq from key", "", nil))
            }
            XCTAssertEqual(value, "id-123")

            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: nil)
            self.apiWasQueried.fulfill()
            return .success(list)
        }

        let syncExpression = DataStoreSyncExpression.syncExpression(MockSynced.schema, where: {
            MockSynced.keys.id == "id-123"
        })
        let operation = initialSyncOperation(withSyncExpression: syncExpression, responder: responder)

        let sink = operation
            .publisher
            .sink(receiveCompletion: { _ in
                self.syncCompletionReceived.fulfill()
            }, receiveValue: { [self] value in
                switch value {
                case .started(modelName: let modelName, syncType: let syncType):
                    XCTAssertEqual(modelName, "MockSynced")
                    XCTAssertEqual(syncType, .fullSync)
                    syncStartedReceived.fulfill()
                case .finished(modelName: let modelName, _):
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

    func testBaseQueryWithFilterSyncExpression() async throws {
        let responder = APIPluginQueryResponder { request in
            XCTAssertEqual(request.document, """
            query SyncMockSynceds($filter: ModelMockSyncedFilterInput, $limit: Int) {
              syncMockSynceds(filter: $filter, limit: $limit) {
                items {
                  id
                  __typename
                  _version
                  _deleted
                  _lastChangedAt
                }
                nextToken
                startedAt
              }
            }
            """)
            guard let filter = request.variables?["filter"] as? [String: Any?] else {
                XCTFail("Unable to get filter")
                return .failure(.unknown("Unable to get filter", "", nil))
            }
            guard let group = filter["or"] as? [[String: Any?]] else {
                XCTFail("Unable to find 'or' group")
                return .failure(.unknown("Unable to find 'or' group", "", nil))
            }

            guard let key = group[0]["id"] as? [String: Any?] else {
                XCTFail("Unable to get id from filter")
                return .failure(.unknown("Unable to get id from filter", "", nil))
            }
            guard let value = key["eq"] as? String else {
                XCTFail("Unable to get eq from key")
                return .failure(.unknown("Unable to get eq from key", "", nil))
            }
            XCTAssertEqual(value, "id-123")

            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: nil)
            self.apiWasQueried.fulfill()
            return .success(list)
        }

        let syncExpression = DataStoreSyncExpression.syncExpression(MockSynced.schema, where: {
            MockSynced.keys.id == "id-123" || MockSynced.keys.id == "id-456"
        })
        let operation = initialSyncOperation(withSyncExpression: syncExpression, responder: responder)

        let sink = operation
            .publisher
            .sink(receiveCompletion: { _ in
                self.syncCompletionReceived.fulfill()
            }, receiveValue: { [self] value in
                switch value {
                case .started(modelName: let modelName, syncType: let syncType):
                    XCTAssertEqual(modelName, "MockSynced")
                    XCTAssertEqual(syncType, .fullSync)
                    syncStartedReceived.fulfill()
                case .finished(modelName: let modelName, _):
                    XCTAssertEqual(modelName, "MockSynced")
                    finishedReceived.fulfill()
                default:
                    break
                }
            })

        operation.main()

        await fulfillment(of: [syncStartedReceived, finishedReceived, apiWasQueried, syncCompletionReceived], timeout: 1)
        sink.cancel()
    }

    func testBaseQueryWithSyncExpressionConstantAll() async throws {
        let responder = APIPluginQueryResponder { request in
            XCTAssertEqual(request.document, """
            query SyncMockSynceds($limit: Int) {
              syncMockSynceds(limit: $limit) {
                items {
                  id
                  __typename
                  _version
                  _deleted
                  _lastChangedAt
                }
                nextToken
                startedAt
              }
            }
            """)
            XCTAssertNil(request.variables?["filter"])

            let list = PaginatedList<AnyModel>(items: [], nextToken: nil, startedAt: nil)
            self.apiWasQueried.fulfill()
            return .success(list)
        }

        let syncExpression = DataStoreSyncExpression.syncExpression(MockSynced.schema, where: {
            QueryPredicateConstant.all
        })
        let operation = initialSyncOperation(withSyncExpression: syncExpression, responder: responder)

        let sink = operation
            .publisher
            .sink(receiveCompletion: { _ in
                self.syncCompletionReceived.fulfill()
            }, receiveValue: { [self] value in
                switch value {
                case .started(modelName: let modelName, syncType: let syncType):
                    XCTAssertEqual(modelName, "MockSynced")
                    XCTAssertEqual(syncType, .fullSync)
                    syncStartedReceived.fulfill()
                case .finished(modelName: let modelName, _):
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
}
