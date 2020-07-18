//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Helper class to fetch log entry related information
struct LogEntryHelper {

    /// Helper function to get current time in a specified format
    static func getDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
        return dateFormatter
    }

    /// Helper function to fetch logs from `PersistentLoggingPlugin`
    static func getLogHistory() -> [LogEntryItem] {
        if let loggingPlugin : PersistentLoggingPlugin =  Amplify.Logging.plugin as? PersistentLoggingPlugin {
            if let logger : PersistentLogWrapper = loggingPlugin.default as? PersistentLogWrapper {
                return logger.getLogHistory()
            }
        }
        
        return [LogEntryItem]()
    }
}
