//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Formatter that conforms to Amplify's standard format for CloudWatch log
/// event messages.
///
/// The standard format is:
///
/// ```
/// $logLevelName/$tag: $message
/// ```
///
/// So, for example:
///
/// ```
/// DEBUG/Storage: Upload complete.
/// ```
///
/// - Tag: CloudWatchLogEntryFormatter
struct CloudWatchLoggingEntryFormatter {

    /// - Returns: String representation of the given entry according to
    /// Amplify's standard format for CloudWatch log event messages.
    ///
    /// - Tag: CloudWatchLogEntryFormatter.format
    func format(entry: LogEntry) -> String {
        return "\(entry.logLevelName)/\(entry.tag): \(entry.message)"
    }
}
