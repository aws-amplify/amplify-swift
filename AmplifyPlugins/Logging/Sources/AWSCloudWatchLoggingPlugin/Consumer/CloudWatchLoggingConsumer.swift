//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import AWSCloudWatchLogs
import AWSClientRuntime
import Amplify
import Foundation

/// Concrete implementation of a [LogConsumer](x-source-tag://LogConsumer)
/// that attempts to upload LogEntry batches to **CloudWatch**.
///
/// NOTE: This implementation assumes that the contents of log files contain a
/// **line-delimited** list of JSON representations of
/// [LogEntry](x-source-tag://LogEntry).
///
/// - See: [LogEntryCodec](x-source-tag://LogEntryCodec)
///
/// - Tag: CloudWatchLogConsumer
class CloudWatchLoggingConsumer {
    
    private let client: CloudWatchLogsClientProtocol
    private let logGroupName: String
    private let logStreamName: String
    private var ensureLogStreamExistsComplete: Bool = false
    
    /// - Tag: CloudWatchLogConsumer.initWithAuthService
    init(
        client: CloudWatchLogsClientProtocol,
        logGroupName: String,
        userIdentifier: String?
    ) throws {
        self.client = client
        let formatter = CloudWatchLoggingStreamNameFormatter(userIdentifier: userIdentifier)
        self.logGroupName = logGroupName
        self.logStreamName = formatter.formattedStreamName()
    }
}

extension CloudWatchLoggingConsumer: LogBatchConsumer {
    func consume(batch: LogBatch) async throws {
        let entries = try batch.readEntries()
        if entries.isEmpty {
            try batch.complete()
            return
        }
        let events = convertToCloudWatchInputLogEvents(for: entries)
        await ensureLogStreamExists()
        let response = try await self.client.putLogEvents(input: PutLogEventsInput(
            logEvents: events,
            logGroupName: self.logGroupName,
            logStreamName: self.logStreamName,
            sequenceToken: nil
        ))
        let retriableEntries = retriable(entries: entries, in: response)
        if !retriableEntries.isEmpty {
            let retriableEvents = convertToCloudWatchInputLogEvents(for: retriableEntries)
            _ = try await self.client.putLogEvents(input: PutLogEventsInput(
                logEvents: retriableEvents,
                logGroupName: self.logGroupName,
                logStreamName: self.logStreamName,
                sequenceToken: nil
            ))
        }
        
        try batch.complete()
    }
    
    private func ensureLogStreamExists() async {
        if ensureLogStreamExistsComplete {
            return
        }
        
        defer {
            ensureLogStreamExistsComplete = true
        }
        
        let stream = try? await self.client.describeLogStreams(input: .init(
            logGroupName: self.logGroupName,
            logStreamNamePrefix: self.logStreamName
        )).logStreams?.first(where: { stream in
            return stream.logStreamName == self.logStreamName
        })
        if stream != nil {
            return
        }
        
        _ = try? await self.client.createLogStream(input: .init(
            logGroupName: self.logGroupName,
            logStreamName: self.logStreamName
        ))
    }
    
    private func convertToCloudWatchInputLogEvents(for entries: [LogEntry]) -> [CloudWatchLogsClientTypes.InputLogEvent] {
        let formatter = CloudWatchLoggingEntryFormatter()
        return entries.map { entry in
            return .init(
                message: formatter.format(entry: entry),
                timestamp: entry.millisecondsSince1970
            )
        }
    }
    
    private func retriable(entries: [LogEntry], in response: PutLogEventsOutputResponse) -> [LogEntry] {
        guard let tooNewLogEventStartIndex = response.rejectedLogEventsInfo?.tooNewLogEventStartIndex else {
            return []
        }
        let totalEntries = entries.count
        if (tooNewLogEventStartIndex < 0 || tooNewLogEventStartIndex >= totalEntries) {
            return []
        }
        
        var retriableEntries: [LogEntry] = []
        for index in tooNewLogEventStartIndex..<totalEntries {
            retriableEntries.append(entries[index])
        }
        return retriableEntries
    }
}
