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
        let mutationEvents = [generateRandomMutationEvent(), generateRandomMutationEvent()]

        let result = MutationEvent.pendingMutationEvents(forMutationEvents: mutationEvents, storageAdapter: storageAdapter)
        switch result {
        case .success(let mutationEvents):
            XCTAssertTrue(mutationEvents.isEmpty)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }

    func testQueryPendingMutationEvent() {
        let mutationEvent = generateRandomMutationEvent()

        let result = storageAdapter.save(
            mutationEvent,
            modelSchema: mutationEvent.schema,
            condition: nil,
            eagerLoad: true
        ).flatMap { model in
            MutationEvent.pendingMutationEvents(
                forMutationEvent: mutationEvent,
                storageAdapter: self.storageAdapter
            )
        }.ifSuccess { mutationEvents in
            XCTAssertEqual(mutationEvents.count, 1)
            XCTAssertEqual(mutationEvents.first?.id, mutationEvent.id)
        }.ifFailure { error in
            XCTFail("\(error)")
        }
    }

    func testQueryPendingMutationEventsForModelIds() {
        let mutationEvent1 = generateRandomMutationEvent()
        let mutationEvent2 = generateRandomMutationEvent()

        let result1 = storageAdapter.save(
            mutationEvent1,
            modelSchema: mutationEvent1.schema,
            condition: nil,
            eagerLoad: true
        )

        if case .failure(let error) = result1 {
            XCTFail("Failed to save metadata, \(error)")
        }

        let result2 = storageAdapter.save(
            mutationEvent2,
            modelSchema: mutationEvent2.schema,
            condition: nil,
            eagerLoad: true
        )
        if case .failure(let error) = result2 {
            XCTFail("Failed to save metadata, \(error)")
        }

        var mutationEvents = [mutationEvent1]
        mutationEvents.append(contentsOf: (1 ... 999).map { _ in generateRandomMutationEvent() })
        mutationEvents.append(mutationEvent2)
        MutationEvent.pendingMutationEvents(
            forMutationEvents: mutationEvents,
            storageAdapter: storageAdapter
        ).ifSuccess({ mutationEvents in
            XCTAssertEqual(mutationEvents.count, 2)
        }).ifFailure({ error in
            XCTFail("\(error)")
        })
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
