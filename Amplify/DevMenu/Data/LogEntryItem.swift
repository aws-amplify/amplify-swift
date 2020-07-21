//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Data class for each log item in Log Viewer Screen
struct LogEntryItem: Identifiable, Hashable {
    var id = UUID()

    /// Log message
    var message: String

    /// Level of the log entry
    var logLevel: LogLevel

    /// Timestamp of the log entry
    var timeStamp: Date
}
