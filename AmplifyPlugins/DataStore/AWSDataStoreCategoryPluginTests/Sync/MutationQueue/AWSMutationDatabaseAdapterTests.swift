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

    let model1 = Post(title: "model1", content: "content1", createdAt: .now())
    let post = Post.keys

    override func setUp() async throws {
        do {
            let mockStorageAdapter = MockSQLiteStorageEngineAdapter()
            databaseAdapter = try AWSMutationDatabaseAdapter(storageAdapter: mockStorageAdapter)
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
        let graphQLFilterJSON = try GraphQLFilterConverter.toJSON(queryPredicate)
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
        let graphQLFilterJSON = try GraphQLFilterConverter.toJSON(queryPredicate)
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
