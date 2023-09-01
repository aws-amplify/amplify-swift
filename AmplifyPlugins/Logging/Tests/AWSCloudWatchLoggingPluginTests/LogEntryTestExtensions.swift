//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

@testable import AWSCloudWatchLoggingPlugin

extension LogEntry {
    static func minimumSizeForLogEntry(level: LogLevel) throws -> Int {
        let entry = LogEntry(category: "", namespace: nil, level: level, message: "", created: Date(timeIntervalSince1970: 0))
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let data = try encoder.encode(entry)
        return data.count
    }
}

extension LogEntry: Comparable {
    public static func < (lhs: LogEntry, rhs: LogEntry) -> Bool {
        if (lhs.created == rhs.created) {
            let formatter = CloudWatchLoggingEntryFormatter()
            return formatter.format(entry: lhs) < formatter.format(entry: rhs)
        }
        return lhs.created < rhs.created
    }
}
