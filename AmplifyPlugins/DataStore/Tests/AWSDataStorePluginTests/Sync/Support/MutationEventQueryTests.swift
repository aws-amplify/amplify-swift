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

    func testQueryPendingMutation_EmptyResult() {
        let querySuccess = expectation(description: "query mutation events success")
        let mutationEvents = [generateRandomMutationEvent(), generateRandomMutationEvent()]

        MutationEvent.pendingMutationEvents(forMutationEvents: mutationEvents, storageAdapter: storageAdapter) { result in
            switch result {
            case .success(let mutationEvents):
                XCTAssertTrue(mutationEvents.isEmpty)
                querySuccess.fulfill()
            case .failure(let error): XCTFail("\(error)")
            }
        }

        wait(for: [querySuccess], timeout: 1)
    }

    func testQueryPendingMutationEvent() {
        let mutationEvent = generateRandomMutationEvent()

        let querySuccess = expectation(description: "query for pending mutation events")

        storageAdapter.save(mutationEvent) { result in
            switch result {
            case .success:
                MutationEvent.pendingMutationEvents(
                    forMutationEvent: mutationEvent,
                    storageAdapter: self.storageAdapter
                ) { result in
                    switch result {
                    case .success(let mutationEvents):
                        XCTAssertEqual(mutationEvents.count, 1)
                        XCTAssertEqual(mutationEvents.first?.id, mutationEvent.id)
                        querySuccess.fulfill()
                    case .failure(let error): XCTFail("\(error)")
                    }
                }
            case .failure(let error): XCTFail("\(error)")
            }
        }
        wait(for: [querySuccess], timeout: 1)
    }

    func testQueryPendingMutationEventsForModelIds() {
        let mutationEvent1 = generateRandomMutationEvent()
        let mutationEvent2 = generateRandomMutationEvent()

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
        var mutationEvents = [mutationEvent1]
        mutationEvents.append(contentsOf: (1 ... 999).map { _ in generateRandomMutationEvent() })
        mutationEvents.append(mutationEvent2)
        MutationEvent.pendingMutationEvents(
            forMutationEvents: mutationEvents,
            storageAdapter: storageAdapter
        ) { result in
            switch result {
            case .success(let mutationEvents):
                XCTAssertEqual(mutationEvents.count, 2)
                querySuccess.fulfill()
            case .failure(let error): XCTFail("\(error)")
            }
        }

        wait(for: [querySuccess], timeout: 1)
    }

    private func generateRandomMutationEvent() -> MutationEvent {
        MutationEvent(
            id: UUID().uuidString,
            modelId: UUID().uuidString,
            modelName: Post.modelName,
            json: "",
            mutationType: .create
        )
    }
}
