////
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Proof-of-concept LogBatch implementation to aid in development.
///
/// - Tag: InMemoryLogBatch
final class InMemoryLogBatch {
    weak var logger: InMemoryLogger?
    let entries: [LogEntry]
    init(entries: [LogEntry]) {
        self.entries = entries
    }
}

extension InMemoryLogBatch: LogBatch {
    func readEntries() throws -> [LogEntry] {
        return entries
    }
    
    func complete(with unprocessed: [LogEntry]) {
        let unprocessedSet = Set(unprocessed)
        let entriesToRemove = entries.filter { unprocessedSet.contains($0) }
        self.logger?.remove(entries: entriesToRemove)
    }
}
