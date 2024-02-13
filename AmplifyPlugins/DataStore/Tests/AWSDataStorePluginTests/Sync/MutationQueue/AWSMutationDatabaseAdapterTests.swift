//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
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
    func test_getNextMutationEvent_AlreadyInProcess() {
        let queryExpectation = expectation(description: "test")
        let expectation = expectation(description: "test")
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
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    /// Retrieve the first MutationEvent
    func test_getNextMutationEvent_MarkInProcess() {
        let queryExpectation = expectation(description: "test")
        let expectation = expectation(description: "test")
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
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
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
