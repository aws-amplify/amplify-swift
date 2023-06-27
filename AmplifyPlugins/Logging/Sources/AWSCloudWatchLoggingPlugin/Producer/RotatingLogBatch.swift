//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Concrete implementation of a [LogBatch](x-source-tag://LogBatch) emitted by a
/// [RotatingLogger](x-source-tag://RotatingLogger)
///
/// - Tag: RotatingLoggerLogBatch
struct RotatingLogBatch {

    /// - Tag: RotatingLoggerLogBatch.created
    var created: Date

    /// - Tag: RotatingLoggerLogBatch.url
    var url: URL

    /// - Tag: RotatingLoggerLogBatch.init
    init(url: URL) {
        self.created = Date()
        self.url = url
    }
}

extension RotatingLogBatch: LogBatch {
    func readEntries() throws -> [LogEntry] {
        let codec = LogEntryCodec()
        let unsorted = try codec.decode(from: url)
        return unsorted.sorted(by: { lhs, rhs in
            return lhs.created < rhs.created
        })
    }

    func complete() throws {
        try FileManager.default.removeItem(at: url)
    }
}
