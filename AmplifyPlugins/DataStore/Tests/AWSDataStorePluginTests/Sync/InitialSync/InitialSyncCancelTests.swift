//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin
@testable import AWSPluginsCore

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class InitialSyncCancelTests: XCTestCase, @unchecked Sendable {

    override func setUp() {
        continueAfterFailure = false
        ModelRegistry.register(modelType: MockSynced.self)
    }

    private static func page(nextToken: String?) -> PaginatedList<AnyModel> {
        PaginatedList<AnyModel>(items: [], nextToken: nextToken, startedAt: Int64(Date().timeIntervalSince1970) * 1_000)
    }

    private func makeStorageAdapter(for schemas: [ModelSchema]) throws -> SQLiteStorageEngineAdapter {
        let storageAdapter = try SQLiteStorageEngineAdapter(connection: Connection(.inMemory))
        try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas + schemas)
        return storageAdapter
    }

    private func makeOperation(
        api: APICategoryGraphQLBehavior,
        reconciliationQueue: IncomingEventReconciliationQueue,
        storageAdapter: StorageEngineAdapter,
        dataStoreConfiguration: DataStoreConfiguration = .testDefault()
    ) -> InitialSyncOperation {
        InitialSyncOperation(
            modelSchema: MockSynced.schema,
            api: api,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter,
            dataStoreConfiguration: dataStoreConfiguration,
            authModeStrategy: AWSDefaultAuthModeStrategy()
        )
    }

    private func waitUntil(timeout: TimeInterval = 2, _ condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try await Task.sleep(nanoseconds: 20 * 1_000_000)
        }
    }

    /// Cancelling mid-pagination stops before the next page is reconciled or lastSync is saved.
    ///
    /// - Given: An InitialSyncOperation syncing two pages
    /// - When:
    ///    - It is cancelled while it fetches the second page
    /// - Then:
    ///    - Only the first page is offered, and no ModelSyncMetadata is saved, so the next sync fetches the rest
    ///
    func testCancelWhileFetchingTheNextPage_doesNotSaveLastSync() async throws {
        let operationBox = AtomicValue<InitialSyncOperation?>(initialValue: nil)
        let queries = AtomicValue(initialValue: 0)
        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestResponse] = QueryRequestResponder<PaginatedList<AnyModel>> { _ in
            guard queries.increment() == 2 else {
                return .success(Self.page(nextToken: "page2"))
            }
            operationBox.get()?.cancel()
            return .success(Self.page(nextToken: nil))
        }
        let storageAdapter = try makeStorageAdapter(for: [MockSynced.schema])
        let reconciliationQueue = MockReconciliationQueue()
        let offers = AtomicValue(initialValue: 0)
        reconciliationQueue.listeners.with { listeners in
            listeners.append { message in
                if message.hasPrefix("offer") {
                    _ = offers.increment()
                }
            }
        }
        let operation = makeOperation(api: apiPlugin, reconciliationQueue: reconciliationQueue, storageAdapter: storageAdapter)
        operationBox.set(operation)
        let completed = expectation(description: "The operation completes")
        let sink = operation.publisher.sink(receiveCompletion: { _ in completed.fulfill() }, receiveValue: { _ in })

        operation.main()

        await fulfillment(of: [completed], timeout: 1)
        sink.cancel()
        XCTAssertEqual(queries.get(), 2)
        XCTAssertEqual(offers.get(), 1)
        XCTAssertNil(try storageAdapter.queryModelSyncMetadata(for: MockSynced.schema))
    }

    /// A query that cancel() cuts short isn't reported as an error.
    ///
    /// - Given: An InitialSyncOperation syncing two pages
    /// - When:
    ///    - It is cancelled while it fetches the second page, and that query fails
    /// - Then:
    ///    - The app's errorHandler isn't called, and no ModelSyncMetadata is saved
    ///
    func testCancelledQueryFailure_doesNotReachTheErrorHandler() async throws {
        let operationBox = AtomicValue<InitialSyncOperation?>(initialValue: nil)
        let queries = AtomicValue(initialValue: 0)
        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestResponse] = QueryRequestResponder<PaginatedList<AnyModel>> { _ in
            guard queries.increment() == 2 else {
                return .success(Self.page(nextToken: "page2"))
            }
            operationBox.get()?.cancel()
            throw APIError.operationError("Cancelled", "", nil)
        }
        let errorHandlerCalls = AtomicValue(initialValue: 0)
        #if os(watchOS)
        let configuration = DataStoreConfiguration.custom(
            errorHandler: { _ in _ = errorHandlerCalls.increment() },
            disableSubscriptions: { false }
        )
        #else
        let configuration = DataStoreConfiguration.custom(errorHandler: { _ in _ = errorHandlerCalls.increment() })
        #endif
        let storageAdapter = try makeStorageAdapter(for: [MockSynced.schema])
        // Held here because the operation keeps only a weak reference
        let reconciliationQueue = MockReconciliationQueue()
        let operation = makeOperation(
            api: apiPlugin,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter,
            dataStoreConfiguration: configuration
        )
        operationBox.set(operation)
        let completed = expectation(description: "The operation completes")
        let sink = operation.publisher.sink(receiveCompletion: { _ in completed.fulfill() }, receiveValue: { _ in })

        operation.main()

        await fulfillment(of: [completed], timeout: 1)
        sink.cancel()
        XCTAssertEqual(queries.get(), 2)
        XCTAssertEqual(errorHandlerCalls.get(), 0)
        XCTAssertNil(try storageAdapter.queryModelSyncMetadata(for: MockSynced.schema))
    }

    /// Cancelling the orchestrator mid-sync saves no lastSync and lets it be freed.
    ///
    /// - Given: An AWSInitialSyncOrchestrator syncing Post and then Comment, one model at a time
    /// - When:
    ///    - It is cancelled while it fetches Post's second page, before Comment's sync has started
    /// - Then:
    ///    - No ModelSyncMetadata is saved for either model
    ///    - Once released, the orchestrator is freed, although Comment's cancelled sync never completes
    ///
    func testOrchestratorCancel_savesNoLastSyncAndFreesTheOrchestrator() async throws {
        ModelRegistry.reset()
        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)

        let orchestratorBox = AtomicValue<AWSInitialSyncOrchestrator?>(initialValue: nil)
        let queries = AtomicValue(initialValue: 0)
        let cancelled = expectation(description: "The orchestrator is cancelled")
        let apiPlugin = MockAPICategoryPlugin()
        apiPlugin.responders[.queryRequestResponse] = QueryRequestResponder<PaginatedList<AnyModel>> { _ in
            guard queries.increment() == 2 else {
                return .success(Self.page(nextToken: "page2"))
            }
            orchestratorBox.get()?.cancel()
            cancelled.fulfill()
            return .success(Self.page(nextToken: nil))
        }
        let storageAdapter = try makeStorageAdapter(for: [Post.schema, Comment.schema])
        // Held here because the sync operations keep only a weak reference
        let reconciliationQueue = MockReconciliationQueue()
        var orchestrator: AWSInitialSyncOrchestrator? = AWSInitialSyncOrchestrator(
            dataStoreConfiguration: .testDefault(),
            authModeStrategy: AWSDefaultAuthModeStrategy(),
            api: apiPlugin,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter
        )
        weak var released = orchestrator
        orchestratorBox.set(orchestrator)
        orchestrator?.sync { _ in }

        await fulfillment(of: [cancelled], timeout: 2)
        // Still held, so releasing it can't be what stops the operations
        try await Task.sleep(nanoseconds: 300 * 1_000_000)
        XCTAssertEqual(queries.get(), 2, "Comment's sync ran after the orchestrator was cancelled")
        XCTAssertNil(try storageAdapter.queryModelSyncMetadata(for: Post.schema))
        XCTAssertNil(try storageAdapter.queryModelSyncMetadata(for: Comment.schema))

        orchestratorBox.set(nil)
        orchestrator = nil
        try await waitUntil { released == nil }
        XCTAssertNil(released, "The orchestrator was kept alive after it was cancelled and released")
    }
}
