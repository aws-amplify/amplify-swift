//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCloudWatchLogs
import Foundation

class AWSCloudWatchClientHelper {
    static func getFilterLogEventCount(
        client: CloudWatchLogsClient?,
        filterPattern: String?,
        startTime: Date?,
        endTime: Date?,
        logGroupName: String?
    ) async throws -> [CloudWatchLogsClientTypes.FilteredLogEvent]? {
        guard let client else { return nil }
        // FilterLogEvents paginates its search across log streams: a single call
        // can return a partial (or empty) event set together with a nextToken,
        // meaning the search is not yet complete. Page through until nextToken is
        // nil so we accumulate every matching event, otherwise the count is
        // non-deterministic and under-reports.
        var allEvents: [CloudWatchLogsClientTypes.FilteredLogEvent] = []
        var nextToken: String?
        repeat {
            let filterEventInput = FilterLogEventsInput(
                endTime: endTime?.epochMilliseconds,
                filterPattern: filterPattern,
                logGroupName: logGroupName,
                nextToken: nextToken,
                startTime: startTime?.epochMilliseconds
            )
            let response = try await client.filterLogEvents(input: filterEventInput)
            allEvents.append(contentsOf: response.events ?? [])
            nextToken = response.nextToken
        } while nextToken != nil
        return allEvents
    }
}

extension Date {
    var epochMilliseconds: Int {
        Int(timeIntervalSince1970 * 1_000)
    }
}
