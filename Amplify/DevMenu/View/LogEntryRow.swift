//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// View for each row in Log Viewer screen
@available(iOS 13.0.0, *)
struct LogEntryRow: View {
    var logEntryItem: LogEntryItem

    var body: some View {
        VStack(alignment: .leading) {
            Group {
                Text(logLevelString).foregroundColor(logLevelTextColor).bold() +
                Text(" ") +
                Text(logEntryItem.message)
            }.lineLimit(2).padding(.bottom, 5)

            Text(LogEntryHelper.dateString(from: logEntryItem.timeStamp))
                .font(.system(size: 15))
                .foregroundColor(Color.secondary)
        }.padding(5)
    }

    /// String to display corresponding to `LogLevel`
    var logLevelString: String {
        switch logEntryItem.logLevel {
        case .debug:
            return "[debug]"
        case .verbose:
            return "[verbose]"
        case .error:
            return "[error]"
        case .warn:
            return "[warn]"
        case .info:
            return "[info]"
        }
    }

    /// Color of `logLevelString` corresponding to `LogLevel`
    var logLevelTextColor: Color {
        switch logEntryItem.logLevel {
        case .debug:
            return Color.gray
        case .verbose:
            return Color.green
        case .error:
            return Color.red
        case .warn:
            return Color.yellow
        case .info:
            return Color.blue
        }
    }
}
