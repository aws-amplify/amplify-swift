//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Concrete implementaiton of LogBatch that reads log file and remove log files.
/// LogBatch/RotatingLogBatch are emited subjects of RotatingLogger.
struct RotatingLogBatch {

    var created: Date

    var url: URL

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
