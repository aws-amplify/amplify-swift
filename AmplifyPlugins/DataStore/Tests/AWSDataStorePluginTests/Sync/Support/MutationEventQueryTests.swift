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
@testable import AWSPluginsCore

class MutationEventQueryTests: BaseDataStoreTests {

    func testQueryPendingMutation_EmptyResult() async {
        let querySuccess = expectation(description: "query mutation events success")
        let modelIds = [UUID().uuidString, UUID().uuidString]

        let result = await MutationEvent.pendingMutationEvents(for: modelIds, storageAdapter: storageAdapter)
        switch result {
        case .success(let mutationEvents):
            XCTAssertTrue(mutationEvents.isEmpty)
            querySuccess.fulfill()
        case .failure(let error): XCTFail("\(error)")
        }
    
        wait(for: [querySuccess], timeout: 1)
    }

    func testQueryPendingMutationEvent() async {
        let mutationEvent = MutationEvent(id: UUID().uuidString,
                                          modelId: UUID().uuidString,
                                          modelName: Post.modelName,
                                          json: "",
                                          mutationType: .create)

        let querySuccess = expectation(description: "query for pending mutation events")

        let saveResult = await storageAdapter.save(mutationEvent)
        switch saveResult {
        case .success:
            let result = await MutationEvent.pendingMutationEvents(for: mutationEvent.modelId,
                                                                   storageAdapter: self.storageAdapter)
            switch result {
            case .success(let mutationEvents):
                XCTAssertEqual(mutationEvents.count, 1)
                XCTAssertEqual(mutationEvents.first?.id, mutationEvent.id)
                querySuccess.fulfill()
            case .failure(let error): XCTFail("\(error)")
            }
            
        case .failure(let error): XCTFail("\(error)")
        }
        
        wait(for: [querySuccess], timeout: 1)
    }

    func testQueryPendingMutationEventsForModelIds() async {
        let mutationEvent1 = MutationEvent(id: UUID().uuidString,
                                           modelId: UUID().uuidString,
                                           modelName: Post.modelName,
                                           json: "",
                                           mutationType: .create)
        let mutationEvent2 = MutationEvent(id: UUID().uuidString,
                                           modelId: UUID().uuidString,
                                           modelName: Post.modelName,
                                           json: "",
                                           mutationType: .create)

        let saveMutationEvent1 = expectation(description: "save mutationEvent1 success")
        storageAdapter.save(mutationEvent1) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            saveMutationEvent1.fulfill()
        }
        wait(for: [saveMutationEvent1], timeout: 1)

        let saveMutationEvent2 = expectation(description: "save mutationEvent1 success")
        storageAdapter.save(mutationEvent2) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            saveMutationEvent2.fulfill()
        }
        wait(for: [saveMutationEvent2], timeout: 1)

        let querySuccess = expectation(description: "query for metadata success")
        var modelIds = [mutationEvent1.modelId]
        modelIds.append(contentsOf: (1 ... 999).map { _ in UUID().uuidString })
        modelIds.append(mutationEvent2.modelId)
        let result = await MutationEvent.pendingMutationEvents(for: modelIds,
                                                               storageAdapter: storageAdapter)
        switch result {
        case .success(let mutationEvents):
            XCTAssertEqual(mutationEvents.count, 2)
            querySuccess.fulfill()
        case .failure(let error): XCTFail("\(error)")
        }

        wait(for: [querySuccess], timeout: 1)
    }
}
