//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite
import XCTest

import AWSPluginsCore
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSMutationDatabaseAdapterTests: XCTestCase, @unchecked Sendable {
    var databaseAdapter: AWSMutationDatabaseAdapter!
    var storageAdapter: MockSQLiteStorageEngineAdapter!
    let model1 = Post(title: "model1", content: "content1", createdAt: .now())
    let post = Post.keys

    override func setUp() {
        do {
            storageAdapter = MockSQLiteStorageEngineAdapter()
            databaseAdapter = try AWSMutationDatabaseAdapter(storageAdapter: storageAdapter)
        } catch {
            XCTFail("Failed to setup system under test")
        }
    }

    func test_replaceLocal_localCreateCandidateUpdate() throws {
        let localCreate = try MutationEvent(
            model: model1,
            modelSchema: model1.schema,
            mutationType: MutationEvent.MutationType.create
        )
        let candidateUpdate = try MutationEvent(
            model: model1,
            modelSchema: model1.schema,
            mutationType: MutationEvent.MutationType.update
        )

        let disposition = databaseAdapter.disposition(for: candidateUpdate, given: [localCreate])

        XCTAssertEqual(disposition, .replaceLocalWithCandidate)
    }

    func test_saveCandidate_CanadidateUpdateWithCondition() throws {
        let anyLocal = try MutationEvent(
            model: model1,
            modelSchema: model1.schema,
            mutationType: MutationEvent.MutationType.create
        )
        let queryPredicate = post.title == model1.title
        let graphQLFilterJSON = try GraphQLFilterConverter.toJSON(queryPredicate, modelSchema: model1.schema)
        let candidateUpdate = try MutationEvent(
            model: model1,
            modelSchema: model1.schema,
            mutationType: MutationEvent.MutationType.update,
            graphQLFilterJSON: graphQLFilterJSON
        )

        let disposition = databaseAdapter.disposition(for: candidateUpdate, given: [anyLocal])
        XCTAssertEqual(disposition, .saveCandidate)
    }

    func test_saveCandidate_CanadidateDeleteWithCondition() throws {
        let anyLocal = try MutationEvent(
            model: model1,
            modelSchema: model1.schema,
            mutationType: MutationEvent.MutationType.create
        )
        let queryPredicate = post.title == model1.title
        let graphQLFilterJSON = try GraphQLFilterConverter.toJSON(queryPredicate, modelSchema: model1.schema)
        let candidateUpdate = try MutationEvent(
            model: model1,
            modelSchema: model1.schema,
            mutationType: MutationEvent.MutationType.delete,
            graphQLFilterJSON: graphQLFilterJSON
        )

        let disposition = databaseAdapter.disposition(for: candidateUpdate, given: [anyLocal])
        XCTAssertEqual(disposition, .saveCandidate)
    }

    func test_replaceLocal_BothUpdate() throws {
        let localCreate = try MutationEvent(
            model: model1,
            modelSchema: model1.schema,
            mutationType: MutationEvent.MutationType.update
        )
        let candidateUpdate = try MutationEvent(
            model: model1,
            modelSchema: model1.schema,
            mutationType: MutationEvent.MutationType.update
        )

        let disposition = databaseAdapter.disposition(for: candidateUpdate, given: [localCreate])

        XCTAssertEqual(disposition, .replaceLocalWithCandidate)
    }

    func test_replaceLocal_localUpdateCandidateDelete() throws {
        let localCreate = try MutationEvent(
            model: model1,
            modelSchema: model1.schema,
            mutationType: MutationEvent.MutationType.update
        )
        let candidateUpdate = try MutationEvent(
            model: model1,
            modelSchema: model1.schema,
            mutationType: MutationEvent.MutationType.delete
        )

        let disposition = databaseAdapter.disposition(for: candidateUpdate, given: [localCreate])

        XCTAssertEqual(disposition, .replaceLocalWithCandidate)
    }

    func test_replaceLocal_BothDelete() throws {
        let localCreate = try MutationEvent(
            model: model1,
            modelSchema: model1.schema,
            mutationType: MutationEvent.MutationType.delete
        )
        let candidateUpdate = try MutationEvent(
            model: model1,
            modelSchema: model1.schema,
            mutationType: MutationEvent.MutationType.delete
        )

        let disposition = databaseAdapter.disposition(for: candidateUpdate, given: [localCreate])

        XCTAssertEqual(disposition, .replaceLocalWithCandidate)
    }

    func test_dropCandidate_localCreateCandidateDelete() throws {
        let localCreate = try MutationEvent(
            model: model1,
            modelSchema: model1.schema,
            mutationType: MutationEvent.MutationType.create
        )
        let candidateUpdate = try MutationEvent(
            model: model1,
            modelSchema: model1.schema,
            mutationType: MutationEvent.MutationType.delete
        )

        let disposition = databaseAdapter.disposition(for: candidateUpdate, given: [localCreate])

        XCTAssertEqual(disposition, .dropCandidateAndDeleteLocal)
    }

    func test_dropCandidateWithError_localItemExistsAlreadyCandidateCreates() throws {
        let localCreate = try MutationEvent(
            model: model1,
            modelSchema: model1.schema,
            mutationType: MutationEvent.MutationType.create
        )
        let candidateUpdate = try MutationEvent(
            model: model1,
            modelSchema: model1.schema,
            mutationType: MutationEvent.MutationType.create
        )

        let disposition = databaseAdapter.disposition(for: candidateUpdate, given: [localCreate])

        XCTAssertEqual(disposition, .dropCandidateWithError(DataStoreError.unknown("", "", nil)))
    }

    func test_dropCandidateWithError_updateMutationForItemMarkedDeleted() throws {
        let localCreate = try MutationEvent(
            model: model1,
            modelSchema: model1.schema,
            mutationType: MutationEvent.MutationType.delete
        )
        let candidateUpdate = try MutationEvent(
            model: model1,
            modelSchema: model1.schema,
            mutationType: MutationEvent.MutationType.update
        )

        let disposition = databaseAdapter.disposition(for: candidateUpdate, given: [localCreate])

        XCTAssertEqual(disposition, .dropCandidateWithError(DataStoreError.unknown("", "", nil)))
    }

    /// Retrieve the first MutationEvent
    func test_getNextMutationEvent_AlreadyInProcess() async {
        let queryExpectation = expectation(description: "query called")
        let getMutationEventCompleted = expectation(description: "getNextMutationEvent completed")
        var mutationEvent1 = MutationEvent(
            modelId: "1111-22",
            modelName: "Post",
            json: "{}",
            mutationType: .create
        )
        mutationEvent1.inProcess = true
        let mutationEvent2 = MutationEvent(
            modelId: "1111-22",
            modelName: "Post",
            json: "{}",
            mutationType: .create
        )
        let queryResponder = QueryModelTypePredicateResponder<MutationEvent> { _, _ in
            queryExpectation.fulfill()
            return .success([mutationEvent1, mutationEvent2])
        }
        storageAdapter.responders[.queryModelTypePredicate] = queryResponder
        databaseAdapter.getNextMutationEvent { result in
            switch result {
            case .success(let mutationEvent):
                XCTAssertTrue(mutationEvent.inProcess)
            case .failure(let error):
                XCTFail("Should have been successful result, error: \(error)")
            }
            getMutationEventCompleted.fulfill()
        }

        await fulfillment(of: [getMutationEventCompleted, queryExpectation], timeout: 1)
    }

    /// Retrieve the first MutationEvent
    func test_getNextMutationEvent_MarkInProcess() async {
        let queryExpectation = expectation(description: "query called")
        let getMutationEventCompleted = expectation(description: "getNextMutationEvent completed")
        let mutationEvent1 = MutationEvent(
            modelId: "1111-22",
            modelName: "Post",
            json: "{}",
            mutationType: .create
        )
        XCTAssertFalse(mutationEvent1.inProcess)
        let mutationEvent2 = MutationEvent(
            modelId: "1111-22",
            modelName: "Post",
            json: "{}",
            mutationType: .create
        )
        let queryResponder = QueryModelTypePredicateResponder<MutationEvent> { _, _ in
            queryExpectation.fulfill()
            return .success([mutationEvent1, mutationEvent2])
        }
        storageAdapter.responders[.queryModelTypePredicate] = queryResponder
        databaseAdapter.getNextMutationEvent { result in
            switch result {
            case .success(let mutationEvent):
                XCTAssertTrue(mutationEvent.inProcess)
            case .failure(let error):
                XCTFail("Should have been successful result, error: \(error)")
            }

            getMutationEventCompleted.fulfill()
        }

        await fulfillment(of: [getMutationEventCompleted, queryExpectation], timeout: 1)
    }

    /// This tests uses an in-memory SQLite connection to save and query mutation events.
    ///
    /// 1. First query will return `m2` since `createdAt`is the oldest, and marked `inProcess` true.
    /// 2. The second query will also return `m2` since `inProcess` does not impact the results
    /// 3. Delete `m2` from the storage
    /// 4. The third query will return `m1` since `m2` was dequeued
    func testGetNextMutationEvent_WithInMemoryStorage() async throws {
        let connection = try Connection(.inMemory)
        let storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
        try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)
        let oldestCreatedAt = Temporal.DateTime.now().add(value: -1, to: .second)
        let newerCreatedAt = Temporal.DateTime.now().add(value: 1, to: .second)
        databaseAdapter.storageAdapter = storageAdapter
        let m1 = MutationEvent(
            modelId: "m1",
            modelName: "Post",
            json: "{}",
            mutationType: .create,
            createdAt: newerCreatedAt,
            inProcess: false
        )
        let m2 = MutationEvent(
            modelId: "m2",
            modelName: "Post",
            json: "{}",
            mutationType: .create,
            createdAt: oldestCreatedAt,
            inProcess: false
        )
        let setUpM1 = storageAdapter.save(m1, modelSchema: MutationEvent.schema)
        guard case .success = setUpM1 else {
            XCTFail("Could not set up mutation event: \(m1)")
            return
        }
        let setUpM2 = storageAdapter.save(m2, modelSchema: MutationEvent.schema)
        guard case .success = setUpM2 else {
            XCTFail("Could not set up mutation event: \(m2)")
            return
        }

        // (1)
        let firstQueryCompleted = expectation(description: "getNextMutationEvent completed")
        databaseAdapter.getNextMutationEvent { result in
            switch result {
            case .success(let mutationEvent):
                XCTAssertTrue(mutationEvent.inProcess)
                XCTAssertEqual(mutationEvent.id, m2.id)
            case .failure(let error):
                XCTFail("Should have been successful result, error: \(error)")
            }

            firstQueryCompleted.fulfill()
        }

        await fulfillment(of: [firstQueryCompleted], timeout: 1)

        // (2)
        let secondQueryCompleted = expectation(description: "getNextMutationEvent completed")
        databaseAdapter.getNextMutationEvent { result in
            switch result {
            case .success(let mutationEvent):
                XCTAssertTrue(mutationEvent.inProcess)
                XCTAssertEqual(mutationEvent.id, m2.id)
            case .failure(let error):
                XCTFail("Should have been successful result, error: \(error)")
            }

            secondQueryCompleted.fulfill()
        }

        await fulfillment(of: [secondQueryCompleted], timeout: 1)

        // (3)
        storageAdapter.delete(
            MutationEvent.self,
            modelSchema: MutationEvent.schema,
            withId: m2.id
        ) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Couldn't delete mutation event, error: \(error)")
            }
        }

        // (4)
        let thirdQueryCompleted = expectation(description: "getNextMutationEvent completed")
        databaseAdapter.getNextMutationEvent { result in
            switch result {
            case .success(let mutationEvent):
                XCTAssertTrue(mutationEvent.inProcess)
                XCTAssertEqual(mutationEvent.id, m1.id)
            case .failure(let error):
                XCTFail("Should have been successful result, error: \(error)")
            }

            thirdQueryCompleted.fulfill()
        }

        await fulfillment(of: [thirdQueryCompleted], timeout: 1)
    }

    // MARK: - Ingest and dequeue interleavings

    /// A request made while a save commits receives the saved event.
    ///
    /// - Given: An empty MutationEvent table, where the outbox requests the next event while the ingester's write of
    ///   a new event is still committing
    /// - When:
    ///    - I submit a create mutation event
    /// - Then:
    ///    - The submit succeeds
    ///    - The outbox's request receives the saved event exactly once, marked in process
    ///    - The stored row is marked in process
    ///
    func testGetNextMutationEvent_requestedWhileASaveCommits_deliversTheSavedEvent() async {
        let table = MockMutationEventTable()
        table.install(on: storageAdapter)
        let delivered = AtomicValue<[MutationEvent]>(initialValue: [])
        let requestFulfilled = expectation(description: "The outbox's request received an event")
        table.willSave = { _, saveIndex in
            guard saveIndex == 1 else { return }
            self.requestNextEvent(recordingIn: delivered, fulfilling: requestFulfilled)
        }
        let event = MutationEvent(modelId: "post-1", modelName: "Post", json: "{}", mutationType: .create)

        await submit(event)
        await fulfillment(of: [requestFulfilled], timeout: 1)

        XCTAssertEqual(delivered.get().map(\.id), [event.id])
        XCTAssertEqual(delivered.get().first?.inProcess, true)
        XCTAssertEqual(table.row(id: event.id)?.inProcess, true)
    }

    /// A parked request receives the oldest unsent event, not the one just saved.
    ///
    /// - Given: The table holds an older, unsent event, and the outbox's first head query reports the table empty, as
    ///   if it ran before that event's write committed
    /// - When:
    ///    - The outbox requests the next event, and the request parks
    ///    - I submit a newer event for another model
    /// - Then:
    ///    - The parked request receives the older event once, marked in process
    ///    - The newer event stays queued, not in process
    ///
    func testGetNextMutationEvent_parkedWhileAnOlderEventIsUnsent_deliversTheOlderEventFirst() async {
        let table = MockMutationEventTable()
        table.install(on: storageAdapter)
        let olderEvent = MutationEvent(
            modelId: "a",
            modelName: "Post",
            json: "{}",
            mutationType: .create,
            createdAt: Temporal.DateTime.now().add(value: -1, to: .second)
        )
        table.insert(olderEvent)
        table.onHeadQuery = { queryIndex, rows in queryIndex == 1 ? [] : rows }
        let delivered = AtomicValue<[MutationEvent]>(initialValue: [])
        let requestFulfilled = expectation(description: "The outbox's request received an event")
        requestNextEvent(recordingIn: delivered, fulfilling: requestFulfilled)
        let newerEvent = MutationEvent(modelId: "b", modelName: "Post", json: "{}", mutationType: .create)

        await submit(newerEvent)
        await fulfillment(of: [requestFulfilled], timeout: 1)

        XCTAssertEqual(delivered.get().map(\.id), [olderEvent.id])
        XCTAssertEqual(delivered.get().first?.inProcess, true)
        XCTAssertEqual(table.row(id: newerEvent.id)?.inProcess, false)
    }

    /// A save merged into the head while it is dequeued is delivered merged.
    ///
    /// - Given: The table holds an unsent create, and the outbox requests the next event while an update for the same
    ///   model is being merged into that create
    /// - When:
    ///    - I submit the update
    /// - Then:
    ///    - The outbox receives the merged event, which carries the update's JSON
    ///    - The table holds that one row, with the update's JSON, marked in process
    ///
    func testSubmit_mergingIntoTheHeadWhileItIsDequeued_deliversTheMergedEvent() async {
        let table = MockMutationEventTable()
        table.install(on: storageAdapter)
        let createEvent = MutationEvent(modelId: "p1", modelName: "Post", json: #"{"v":1}"#, mutationType: .create)
        table.insert(createEvent)
        let delivered = AtomicValue<[MutationEvent]>(initialValue: [])
        let requestFulfilled = expectation(description: "The outbox's request received an event")
        table.willSave = { _, saveIndex in
            guard saveIndex == 1 else { return }
            self.requestNextEvent(recordingIn: delivered, fulfilling: requestFulfilled)
        }
        let updateEvent = MutationEvent(modelId: "p1", modelName: "Post", json: #"{"v":2}"#, mutationType: .update)

        await submit(updateEvent)
        await fulfillment(of: [requestFulfilled], timeout: 1)

        XCTAssertEqual(delivered.get().map(\.id), [createEvent.id])
        XCTAssertEqual(delivered.get().first?.json, updateEvent.json)
        let rows = table.rows
        XCTAssertEqual(rows.map(\.id), [createEvent.id])
        XCTAssertEqual(rows.first?.json, updateEvent.json)
        XCTAssertEqual(rows.first?.inProcess, true)
    }

    /// A new request replaces a parked one.
    ///
    /// - Given: An empty table, and an outbox request that parked on it
    /// - When:
    ///    - An event is written directly to the table, and the outbox requests again
    ///    - I then submit an event for another model
    /// - Then:
    ///    - The second request receives the directly written event
    ///    - The first request is never called
    ///    - The submitted event stays queued, not in process
    ///
    func testGetNextMutationEvent_newRequest_replacesAParkedRequest() async {
        let table = MockMutationEventTable()
        table.install(on: storageAdapter)
        let firstHeadQuery = expectation(description: "The first request queried the table")
        table.onHeadQuery = { queryIndex, rows in
            if queryIndex == 1 {
                firstHeadQuery.fulfill()
            }
            return rows
        }
        let firstRequestCalls = AtomicValue(initialValue: 0)
        databaseAdapter.getNextMutationEvent { _ in
            _ = firstRequestCalls.increment()
        }
        await fulfillment(of: [firstHeadQuery], timeout: 1)

        let directEvent = MutationEvent(
            modelId: "a",
            modelName: "Post",
            json: "{}",
            mutationType: .create,
            createdAt: Temporal.DateTime.now().add(value: -1, to: .second)
        )
        table.insert(directEvent)
        let delivered = AtomicValue<[MutationEvent]>(initialValue: [])
        let secondRequestFulfilled = expectation(description: "The second request received an event")
        requestNextEvent(recordingIn: delivered, fulfilling: secondRequestFulfilled)
        await fulfillment(of: [secondRequestFulfilled], timeout: 1)

        let submittedEvent = MutationEvent(modelId: "b", modelName: "Post", json: "{}", mutationType: .create)
        await submit(submittedEvent)

        XCTAssertEqual(delivered.get().map(\.id), [directEvent.id])
        XCTAssertEqual(firstRequestCalls.get(), 0)
        XCTAssertEqual(table.row(id: submittedEvent.id)?.inProcess, false)
    }

    /// A save made while the outbox waits is delivered once, and the next save is queued.
    ///
    /// - Given: An empty table and a parked outbox request
    /// - When:
    ///    - I submit a create, then an update for the same model
    /// - Then:
    ///    - The request receives the create exactly once, marked in process
    ///    - The update is queued as its own row, not merged into the in-process create
    ///
    func testSubmit_whileTheOutboxWaits_deliversOnceAndQueuesTheNextSave() async {
        let table = MockMutationEventTable()
        table.install(on: storageAdapter)
        let delivered = AtomicValue<[MutationEvent]>(initialValue: [])
        let requestFulfilled = expectation(description: "The outbox's request received an event")
        requestNextEvent(recordingIn: delivered, fulfilling: requestFulfilled)
        let createEvent = MutationEvent(
            modelId: "p1",
            modelName: "Post",
            json: #"{"v":1}"#,
            mutationType: .create,
            createdAt: Temporal.DateTime.now().add(value: -1, to: .second)
        )
        let updateEvent = MutationEvent(modelId: "p1", modelName: "Post", json: #"{"v":2}"#, mutationType: .update)

        await submit(createEvent)
        await fulfillment(of: [requestFulfilled], timeout: 1)
        await submit(updateEvent)

        XCTAssertEqual(delivered.get().map(\.id), [createEvent.id])
        XCTAssertEqual(delivered.get().first?.inProcess, true)
        let rows = table.rows
        XCTAssertEqual(rows.map(\.id), [createEvent.id, updateEvent.id])
        XCTAssertEqual(rows.map(\.mutationType), [MutationEvent.MutationType.create.rawValue, MutationEvent.MutationType.update.rawValue])
        XCTAssertEqual(rows.map(\.inProcess), [true, false])
    }

    /// A save that fails after its write still serves the parked request.
    ///
    /// - Given: An empty table, a parked outbox request, and a storage adapter whose first save writes its row but
    ///   then reports a failure, as when reading the saved row back fails
    /// - When:
    ///    - I submit a create mutation event
    /// - Then:
    ///    - The submit fails
    ///    - The parked request still receives the written event, marked in process
    ///
    func testSubmit_whenTheSaveFailsAfterItsWrite_stillServesTheParkedRequest() async {
        let table = MockMutationEventTable()
        table.install(on: storageAdapter)
        let saveCount = AtomicValue(initialValue: 0)
        storageAdapter.responders[.saveModelCompletion] = SaveModelCompletionResponder<MutationEvent> { mutationEvent, completion in
            table.insert(mutationEvent)
            if saveCount.increment() == 1 {
                completion(.failure(.internalOperation("The saved row could not be read back", "", nil)))
            } else {
                completion(.success(mutationEvent))
            }
        }
        let delivered = AtomicValue<[MutationEvent]>(initialValue: [])
        let requestFulfilled = expectation(description: "The outbox's request received an event")
        requestNextEvent(recordingIn: delivered, fulfilling: requestFulfilled)
        let event = MutationEvent(modelId: "post-1", modelName: "Post", json: "{}", mutationType: .create)

        let submitFailed = expectation(description: "submit failed")
        databaseAdapter.submit(mutationEvent: event) { result in
            if case .success = result {
                XCTFail("The submit should report the save's failure")
            }
            submitFailed.fulfill()
        }
        await fulfillment(of: [submitFailed, requestFulfilled], timeout: 1)

        XCTAssertEqual(delivered.get().map(\.id), [event.id])
        XCTAssertEqual(delivered.get().first?.inProcess, true)
        XCTAssertEqual(table.row(id: event.id)?.inProcess, true)
    }

    // MARK: - Helpers

    /// Requests the next event, recording each delivery
    private func requestNextEvent(recordingIn delivered: AtomicValue<[MutationEvent]>, fulfilling expectation: XCTestExpectation) {
        databaseAdapter.getNextMutationEvent { result in
            switch result {
            case .success(let mutationEvent):
                delivered.append(mutationEvent)
            case .failure(let error):
                XCTFail("Unexpected failure: \(error)")
            }
            expectation.fulfill()
        }
    }

    private func submit(_ mutationEvent: MutationEvent) async {
        let submitted = expectation(description: "submit completed for \(mutationEvent.modelId)")
        databaseAdapter.submit(mutationEvent: mutationEvent) { result in
            if case .failure(let error) = result {
                XCTFail("Unexpected failure: \(error)")
            }
            submitted.fulfill()
        }
        await fulfillment(of: [submitted], timeout: 1)
    }
}

extension AWSMutationDatabaseAdapter.MutationDisposition: Equatable {
    public static func == (
        lhs: AWSMutationDatabaseAdapter.MutationDisposition,
        rhs: AWSMutationDatabaseAdapter.MutationDisposition
    ) -> Bool {
        switch (lhs, rhs) {
        case (.dropCandidateWithError, .dropCandidateWithError):
            return true
        case (.saveCandidate, .saveCandidate):
            return true
        case (.replaceLocalWithCandidate, .replaceLocalWithCandidate):
            return true
        case (.dropCandidateAndDeleteLocal, .dropCandidateAndDeleteLocal):
            return true
        default:
            return false
        }
    }
}
