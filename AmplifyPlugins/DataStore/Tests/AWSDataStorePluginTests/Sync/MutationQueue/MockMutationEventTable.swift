//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@testable import Amplify
@testable import AWSDataStorePlugin

/// In-memory MutationEvent table whose hooks run inside storage calls, to replay outbox and ingester races exactly.
/// - Note: `@unchecked Sendable`: state is guarded by `lock`, and hooks are called outside it.
final class MockMutationEventTable: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [MutationEvent] = []
    private var saveCount = 0
    private var headQueryCount = 0
    private var willSaveHook: ((MutationEvent, Int) -> Void)?
    private var onHeadQueryHook: ((Int, [MutationEvent]) -> [MutationEvent])?

    /// Called before a save is written, with the event and the 1-based index of the save
    var willSave: ((MutationEvent, Int) -> Void)? {
        get { lock.execute { willSaveHook } }
        set { lock.execute { willSaveHook = newValue } }
    }

    /// Called on each head query (no predicate) with its 1-based index and the sorted rows; returns the rows to report
    var onHeadQuery: ((Int, [MutationEvent]) -> [MutationEvent])? {
        get { lock.execute { onHeadQueryHook } }
        set { lock.execute { onHeadQueryHook = newValue } }
    }

    /// The rows, oldest `createdAt` first, in insertion order for equal dates
    var rows: [MutationEvent] {
        lock.execute {
            storage.enumerated()
                .sorted { ($0.element.createdAt, $0.offset) < ($1.element.createdAt, $1.offset) }
                .map(\.element)
        }
    }

    func row(id: String) -> MutationEvent? {
        lock.execute { storage.first { $0.id == id } }
    }

    /// Writes a row directly, as a writer outside the adapter would
    func insert(_ mutationEvent: MutationEvent) {
        lock.execute {
            if let index = storage.firstIndex(where: { $0.id == mutationEvent.id }) {
                storage[index] = mutationEvent
            } else {
                storage.append(mutationEvent)
            }
        }
    }

    /// Answers the adapter's MutationEvent queries, saves and untyped deletes from this table
    func install(on storageAdapter: MockSQLiteStorageEngineAdapter) {
        storageAdapter.responders[.queryModelTypePredicate] = QueryModelTypePredicateResponder<MutationEvent> { _, predicate in
            guard let predicate else {
                return .success(self.headQuery())
            }
            return .success(self.rows.filter { predicate.evaluate(target: $0) })
        }
        storageAdapter.responders[.saveModelCompletion] = SaveModelCompletionResponder<MutationEvent> { mutationEvent, completion in
            self.save(mutationEvent)
            completion(.success(mutationEvent))
        }
        storageAdapter.responders[.deleteUntypedModel] = DeleteUntypedModelCompletionResponder { _, id in
            self.lock.execute { self.storage.removeAll { $0.id == id } }
            return .emptyResult
        }
    }

    private func headQuery() -> [MutationEvent] {
        let (index, hook) = lock.execute {
            headQueryCount += 1
            return (headQueryCount, onHeadQueryHook)
        }
        let sortedRows = rows
        return hook?(index, sortedRows) ?? sortedRows
    }

    private func save(_ mutationEvent: MutationEvent) {
        let (index, hook) = lock.execute {
            saveCount += 1
            return (saveCount, willSaveHook)
        }
        hook?(mutationEvent, index)
        insert(mutationEvent)
    }
}
