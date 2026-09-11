//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

// Transaction body succeeds locally, then fails on close (the reporter's SQLite error).
final class RollbackFailingStorageAdapter: MockSQLiteStorageEngineAdapter {
    override func exists(
        _ modelSchema: ModelSchema,
        withIdentifier id: ModelIdentifierProtocol,
        predicate: QueryPredicate?
    ) throws -> Bool {
        false
    }

    override func save<M: Model>(
        _ model: M,
        modelSchema: ModelSchema,
        condition: QueryPredicate?,
        eagerLoad: Bool
    ) -> DataStoreResult<M> {
        .success(model)
    }

    override func transaction(_ basicClosure: () throws -> Void) throws {
        try basicClosure()
        throw DataStoreError.invalidOperation(
            causedBy: NSError(
                domain: "SQLite",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "cannot rollback - no transaction is active (code: 1)"]
            )
        )
    }
}

// Local write returns a failure without throwing.
final class LocalSaveFailingStorageAdapter: MockSQLiteStorageEngineAdapter {
    override func exists(
        _ modelSchema: ModelSchema,
        withIdentifier id: ModelIdentifierProtocol,
        predicate: QueryPredicate?
    ) throws -> Bool {
        false
    }

    override func save<M: Model>(
        _ model: M,
        modelSchema: ModelSchema,
        condition: QueryPredicate?,
        eagerLoad: Bool
    ) -> DataStoreResult<M> {
        .failure(.internalOperation("forced local save failure", "", nil))
    }
}

class StorageEngineTestsSaveDoubleResume: XCTestCase {

    override func setUp() {
        super.setUp()
        ModelRegistry.register(modelType: Post.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
        super.tearDown()
    }

    private func makeStorageEngine(
        adapter: StorageEngineAdapter,
        syncEngine: RemoteSyncEngineBehavior? = {
            let engine = MockRemoteSyncEngine()
            engine.syncing = true
            return engine
        }()
    ) -> StorageEngine {
        StorageEngine(
            storageAdapter: adapter,
            dataStoreConfiguration: .testDefault(),
            syncEngine: syncEngine,
            validAPIPluginKey: "MockAPICategoryPlugin",
            validAuthPluginKey: "MockAuthCategoryPlugin",
            isSyncEnabled: true
        )
    }

    private func makePlugin(_ storageEngine: StorageEngine) -> AWSDataStorePlugin {
        let plugin = AWSDataStorePlugin(
            modelRegistration: TestModelRegistration(),
            dataStorePublisher: DataStorePublisher(),
            validAPIPluginKey: "MockAPICategoryPlugin",
            validAuthPluginKey: "MockAuthCategoryPlugin"
        )
        plugin.storageEngine = storageEngine
        return plugin
    }

    private func realInMemoryAdapter() throws -> SQLiteStorageEngineAdapter {
        let adapter = try SQLiteStorageEngineAdapter(connection: try Connection(.inMemory))
        try adapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)
        try adapter.setUp(modelSchemas: [Post.schema])
        return adapter
    }

    private func save(_ post: Post, on storageEngine: StorageEngine) async -> DataStoreResult<Post> {
        await withCheckedContinuation { continuation in
            storageEngine.save(post, modelSchema: Post.schema) { continuation.resume(returning: $0) }
        }
    }

    /// - Given: a save whose transaction fails to close after the body ran
    /// - When: the model is saved through the async `DataStore.save` API
    /// - Then: the async API surfaces the failure instead of crashing with a continuation misuse
    func testSaveWithTransactionCloseFailureSurfacesError() async throws {
        let plugin = makePlugin(makeStorageEngine(adapter: RollbackFailingStorageAdapter()))
        let post = Post(title: "repro-3716", content: "double resume", createdAt: .now())

        var caughtError: Error?
        do {
            _ = try await plugin.save(post)
            XCTFail("save should fail because the transaction failed to close")
        } catch {
            caughtError = error
        }
        XCTAssertNotNil(caughtError, "Transaction close failure must surface as an error, not a crash")
    }

    /// - Given: a real SQLite store and a sync engine
    /// - When: a model is saved normally
    /// - Then: the save succeeds, persists locally, and invokes completion exactly once
    func testNormalSaveThroughRealSQLitePersistsAndCompletesOnce() async throws {
        let plugin = makePlugin(makeStorageEngine(adapter: try realInMemoryAdapter()))
        let post = Post(title: "e2e-3716", content: "normal save", createdAt: .now())

        let saved = try await plugin.save(post)
        XCTAssertEqual(saved.id, post.id)
        XCTAssertEqual(saved.title, "e2e-3716")

        let queried = try await plugin.query(Post.self, byId: post.id)
        XCTAssertNotNil(queried)
        XCTAssertEqual(queried?.id, post.id)
    }

    /// - Given: a local write that returns a failure
    /// - When: the model is saved
    /// - Then: that failure is reported exactly once
    func testSaveWithLocalWriteFailureReturnsFailure() async throws {
        let storageEngine = makeStorageEngine(adapter: LocalSaveFailingStorageAdapter())
        let post = Post(title: "localfail-3716", content: "local write fails", createdAt: .now())

        let result = await save(post, on: storageEngine)
        guard case .failure = result else {
            XCTFail("Expected the local save failure to surface, got \(String(describing: result))")
            return
        }
    }

    /// - Given: a real SQLite store with no sync engine available
    /// - When: a syncable model is saved
    /// - Then: the save fails and the local row is rolled back (not left persisted)
    func testSaveWithoutSyncEngineRollsBackLocalWrite() async throws {
        let adapter = try realInMemoryAdapter()
        let storageEngine = makeStorageEngine(adapter: adapter, syncEngine: nil)
        let post = Post(title: "rollback-3716", content: "no sync engine", createdAt: .now())

        let result = await save(post, on: storageEngine)
        guard case .failure = result else {
            XCTFail("Expected a failure when no sync engine is available, got \(String(describing: result))")
            return
        }

        let queried = try await withCheckedContinuation { continuation in
            storageEngine.query(
                Post.self,
                modelSchema: Post.schema,
                predicate: Post.keys.id == post.id,
                sort: nil,
                paginationInput: nil,
                eagerLoad: true
            ) { continuation.resume(returning: $0) }
        }
        guard case .success(let posts) = queried else {
            XCTFail("query failed: \(String(describing: queried))")
            return
        }
        XCTAssertTrue(posts.isEmpty, "row must be rolled back after a save with no sync engine")
    }

    /// - Given: a real SQLite store
    /// - When: the same model is saved twice (as a retry would)
    /// - Then: exactly one row exists — retries are idempotent, not duplicated
    func testRepeatedSaveOfSameModelDoesNotDuplicate() async throws {
        let plugin = makePlugin(makeStorageEngine(adapter: try realInMemoryAdapter()))
        let post = Post(title: "idempotent-3716", content: "saved twice", createdAt: .now())

        _ = try await plugin.save(post)
        _ = try await plugin.save(post)

        let all = try await plugin.query(Post.self, where: Post.keys.id == post.id)
        XCTAssertEqual(all.count, 1, "saving the same model twice must not create a duplicate row")
    }

    /// - Given: a save whose transaction fails to close, with a sync engine that spies on hand-off
    /// - When: saved through the completion-based StorageEngine API
    /// - Then: completion fires exactly once and the sync hand-off never runs. A symptom-suppressed
    ///   fix would either resume completion twice (caught by `assertForOverFulfill`) or reach the
    ///   hand-off (caught by the inverted `handoffAttempted` expectation).
    func testTransactionCloseFailureInvokesCompletionExactlyOnce() {
        let syncEngine = MockRemoteSyncEngine()
        syncEngine.syncing = true
        let handoffAttempted = expectation(description: "sync hand-off must not run when the transaction fails to close")
        handoffAttempted.isInverted = true
        syncEngine.setCallbackOnSubmit { mutationEvent, completion in
            handoffAttempted.fulfill()
            completion(.success(mutationEvent))
        }

        let storageEngine = makeStorageEngine(adapter: RollbackFailingStorageAdapter(), syncEngine: syncEngine)
        let post = Post(title: "count-3716", content: "exactly once", createdAt: .now())

        let completed = expectation(description: "completion called")
        completed.assertForOverFulfill = true
        let lock = NSLock()
        var invocations = 0
        var lastResult: DataStoreResult<Post>?
        storageEngine.save(post, modelSchema: Post.schema) { result in
            lock.lock()
            invocations += 1
            lastResult = result
            lock.unlock()
            completed.fulfill()
        }
        wait(for: [completed, handoffAttempted], timeout: 1)

        XCTAssertEqual(invocations, 1, "completion must be invoked exactly once")
        guard case .failure = lastResult else {
            XCTFail("Expected a failure, got \(String(describing: lastResult))")
            return
        }
    }
}
