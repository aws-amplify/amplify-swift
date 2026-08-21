//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalCloudWatchLogging

/// Concrete implementation of LogBatch that reads log file and removes log files.
struct RotatingLogBatch: LogBatch {
    var url: URL

    init(url: URL) {
        self.url = url
    }

    func readEntries() throws -> [any LogEntryRepresentable] {
        let codec = LogEntryCodec()
        let unsorted = try codec.decode(from: url)
        return unsorted.sorted(by: { lhs, rhs in
            return lhs.created < rhs.created
        })
    }

    func complete() throws {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            throw CloudWatchError.storage(
                "Failed to remove log file at \(url)",
                "This is an internal error. Please file a bug report.",
                error
            )
        }
    }
}
