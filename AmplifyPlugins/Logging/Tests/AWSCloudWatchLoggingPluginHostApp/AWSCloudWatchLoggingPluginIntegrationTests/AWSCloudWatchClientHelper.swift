//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCloudWatchLogs

class AWSCloudWatchClientHelper {
    static func getFilterLogEventCount(client: CloudWatchLogsClientProtocol?, filterPattern: String?, startTime: Date?, endTime: Date?, logGroupName: String?) async throws -> [CloudWatchLogsClientTypes.FilteredLogEvent]? {
        let filterEventInput = FilterLogEventsInput(endTime: endTime?.epochMilliseconds, filterPattern: filterPattern, logGroupName: logGroupName, startTime: startTime?.epochMilliseconds)
        let response = try await client?.filterLogEvents(input: filterEventInput)
        return response?.events
    }
}

extension Date {
    var epochMilliseconds: Int {
        Int(self.timeIntervalSince1970 * 1_000)
    }
}
