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
@testable import AWSPluginsCore
@testable import AWSDataStorePlugin

class MutationEventClearStateTests: XCTestCase {
    var mockStorageAdapter: MockSQLiteStorageEngineAdapter!
    var mutationEventClearState: MutationEventClearState!

    override func setUp() {
        mockStorageAdapter = MockSQLiteStorageEngineAdapter()
        mutationEventClearState = MutationEventClearState(storageAdapter: mockStorageAdapter)
    }

    func testInProcessIsSetFromTrueToFalse() {
        let queryExpectation = expectation(description: "query is called")
        let saveExpectation = expectation(description: "save is Called")
        let completionExpectation = expectation(description: "completion handler is called")

        let queryResponder: QueryModelTypePredicateResponder<MutationEvent> = { _, _ in
                queryExpectation.fulfill()
                var mutationEvent = MutationEvent(modelId: "1111-22",
                                                  modelName: "Post",
                                                  json: "{}",
                                                  mutationType: .create)
                mutationEvent.inProcess = true
                return .success([mutationEvent])
        }
        mockStorageAdapter.responders[.queryModelTypePredicate] = queryResponder

        let saveResponder: SaveModelCompletionResponder<MutationEvent> = { model in
            XCTAssertEqual("1111-22", model.modelId)
            XCTAssertFalse(model.inProcess)
            saveExpectation.fulfill()
            return .success(model)
        }
        mockStorageAdapter.responders[.saveModelCompletion] = saveResponder

        mutationEventClearState.clearStateOutgoingMutations {
            completionExpectation.fulfill()
        }
        wait(for: [queryExpectation,
                   saveExpectation,
                   completionExpectation], timeout: 1.0)
    }
}
