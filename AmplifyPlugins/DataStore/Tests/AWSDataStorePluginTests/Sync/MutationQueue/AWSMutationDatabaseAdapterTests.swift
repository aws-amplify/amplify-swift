//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin
import AWSPluginsCore

class AWSMutationDatabaseAdapterTests: XCTestCase {
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
        let localCreate = try MutationEvent(model: model1,
                                            modelSchema: model1.schema,
                                            mutationType: MutationEvent.MutationType.create)
        let candidateUpdate = try MutationEvent(model: model1,
                                                modelSchema: model1.schema,
                                                mutationType: MutationEvent.MutationType.update)

        let disposition = databaseAdapter.disposition(for: candidateUpdate, given: [localCreate])

        XCTAssertEqual(disposition, .replaceLocalWithCandidate)
    }

    func test_saveCandidate_CanadidateUpdateWithCondition() throws {
        let anyLocal = try MutationEvent(model: model1,
                                         modelSchema: model1.schema,
                                         mutationType: MutationEvent.MutationType.create)
        let queryPredicate = post.title == model1.title
        let graphQLFilterJSON = try GraphQLFilterConverter.toJSON(queryPredicate, modelSchema: model1.schema)
        let candidateUpdate = try MutationEvent(model: model1,
                                                modelSchema: model1.schema,
                                                mutationType: MutationEvent.MutationType.update,
                                                graphQLFilterJSON: graphQLFilterJSON)

        let disposition = databaseAdapter.disposition(for: candidateUpdate, given: [anyLocal])
        XCTAssertEqual(disposition, .saveCandidate)
    }

    func test_saveCandidate_CanadidateDeleteWithCondition() throws {
        let anyLocal = try MutationEvent(model: model1,
                                         modelSchema: model1.schema,
                                         mutationType: MutationEvent.MutationType.create)
        let queryPredicate = post.title == model1.title
        let graphQLFilterJSON = try GraphQLFilterConverter.toJSON(queryPredicate, modelSchema: model1.schema)
        let candidateUpdate = try MutationEvent(model: model1,
                                                modelSchema: model1.schema,
                                                mutationType: MutationEvent.MutationType.delete,
                                                graphQLFilterJSON: graphQLFilterJSON)

        let disposition = databaseAdapter.disposition(for: candidateUpdate, given: [anyLocal])
        XCTAssertEqual(disposition, .saveCandidate)
    }

    func test_replaceLocal_BothUpdate() throws {
        let localCreate = try MutationEvent(model: model1,
                                            modelSchema: model1.schema,
                                            mutationType: MutationEvent.MutationType.update)
        let candidateUpdate = try MutationEvent(model: model1,
                                                modelSchema: model1.schema,
                                                mutationType: MutationEvent.MutationType.update)

        let disposition = databaseAdapter.disposition(for: candidateUpdate, given: [localCreate])

        XCTAssertEqual(disposition, .replaceLocalWithCandidate)
    }

    func test_replaceLocal_localUpdateCandidateDelete() throws {
        let localCreate = try MutationEvent(model: model1,
                                            modelSchema: model1.schema,
                                            mutationType: MutationEvent.MutationType.update)
        let candidateUpdate = try MutationEvent(model: model1,
                                                modelSchema: model1.schema,
                                                mutationType: MutationEvent.MutationType.delete)

        let disposition = databaseAdapter.disposition(for: candidateUpdate, given: [localCreate])

        XCTAssertEqual(disposition, .replaceLocalWithCandidate)
    }

    func test_replaceLocal_BothDelete() throws {
        let localCreate = try MutationEvent(model: model1,
                                            modelSchema: model1.schema,
                                            mutationType: MutationEvent.MutationType.delete)
        let candidateUpdate = try MutationEvent(model: model1,
                                                modelSchema: model1.schema,
                                                mutationType: MutationEvent.MutationType.delete)

        let disposition = databaseAdapter.disposition(for: candidateUpdate, given: [localCreate])

        XCTAssertEqual(disposition, .replaceLocalWithCandidate)
    }

    func test_dropCandidate_localCreateCandidateDelete() throws {
        let localCreate = try MutationEvent(model: model1,
                                            modelSchema: model1.schema,
                                            mutationType: MutationEvent.MutationType.create)
        let candidateUpdate = try MutationEvent(model: model1,
                                                modelSchema: model1.schema,
                                                mutationType: MutationEvent.MutationType.delete)

        let disposition = databaseAdapter.disposition(for: candidateUpdate, given: [localCreate])

        XCTAssertEqual(disposition, .dropCandidateAndDeleteLocal)
    }

    func test_dropCandidateWithError_localItemExistsAlreadyCandidateCreates() throws {
        let localCreate = try MutationEvent(model: model1,
                                            modelSchema: model1.schema,
                                            mutationType: MutationEvent.MutationType.create)
        let candidateUpdate = try MutationEvent(model: model1,
                                                modelSchema: model1.schema,
                                                mutationType: MutationEvent.MutationType.create)

        let disposition = databaseAdapter.disposition(for: candidateUpdate, given: [localCreate])

        XCTAssertEqual(disposition, .dropCandidateWithError(DataStoreError.unknown("", "", nil)))
    }

    func test_dropCandidateWithError_updateMutationForItemMarkedDeleted() throws {
        let localCreate = try MutationEvent(model: model1,
                                            modelSchema: model1.schema,
                                            mutationType: MutationEvent.MutationType.delete)
        let candidateUpdate = try MutationEvent(model: model1,
                                                modelSchema: model1.schema,
                                                mutationType: MutationEvent.MutationType.update)

        let disposition = databaseAdapter.disposition(for: candidateUpdate, given: [localCreate])

        XCTAssertEqual(disposition, .dropCandidateWithError(DataStoreError.unknown("", "", nil)))
    }
    
    /// Retrieve the first MutationEvent
    func test_getNextMutationEvent_AlreadyInProcess() async {
        let queryExpectation = expectation(description: "query called")
        let getMutationEventCompleted = expectation(description: "getNextMutationEvent completed")
        var mutationEvent1 = MutationEvent(modelId: "1111-22",
                                           modelName: "Post",
                                           json: "{}",
                                           mutationType: .create)
        mutationEvent1.inProcess = true
        let mutationEvent2 = MutationEvent(modelId: "1111-22",
                                           modelName: "Post",
                                           json: "{}",
                                           mutationType: .create)
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
        let mutationEvent1 = MutationEvent(modelId: "1111-22",
                                           modelName: "Post",
                                           json: "{}",
                                           mutationType: .create)
        XCTAssertFalse(mutationEvent1.inProcess)
        let mutationEvent2 = MutationEvent(modelId: "1111-22",
                                           modelName: "Post",
                                           json: "{}",
                                           mutationType: .create)
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
        let m1 = MutationEvent(modelId: "m1",
                               modelName: "Post",
                               json: "{}",
                               mutationType: .create,
                               createdAt: newerCreatedAt,
                               inProcess: false)
        let m2 = MutationEvent(modelId: "m2",
                               modelName: "Post",
                               json: "{}",
                               mutationType: .create,
                               createdAt: oldestCreatedAt,
                               inProcess: false)
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
        storageAdapter.delete(MutationEvent.self, 
                              modelSchema: MutationEvent.schema,
                              withId: m2.id) { result in
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
}

extension AWSMutationDatabaseAdapter.MutationDisposition: Equatable {
    public static func == (lhs: AWSMutationDatabaseAdapter.MutationDisposition,
                           rhs: AWSMutationDatabaseAdapter.MutationDisposition) -> Bool {
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
