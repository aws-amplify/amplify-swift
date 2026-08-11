//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Formatter for CloudWatch log event messages.
///
/// The standard format is:
/// ```
/// $logLevelName/$namespace: $message
/// ```
struct CloudWatchLoggingEntryFormatter {

    func format(entry: LogEntry) -> String {
        return "\(entry.logLevelName)/\(entry.namespace): \(entry.message)"
    }
}
