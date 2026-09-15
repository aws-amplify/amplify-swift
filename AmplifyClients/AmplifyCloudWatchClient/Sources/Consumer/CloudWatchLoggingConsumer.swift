//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AWSCloudWatchLogs
import Combine
import Foundation
import InternalCloudWatchLogging

class CloudWatchLoggingConsumer: @unchecked Sendable {

    private let client: CloudWatchLogsClientProtocol
    private let formatter: CloudWatchLoggingStreamNameFormatter
    private let entryFormatter = CloudWatchLoggingEntryFormatter()
    private let logGroupName: String
    private var logStreamName: String?
    private var ensureLogStreamExistsComplete: Bool = false
    private let logger = AmplifyFoundation.AmplifyLogging.logger(for: CloudWatchLoggingConsumer.self)
    private let eventSubject: PassthroughSubject<LoggingEvent, Never>?

    init(
        client: CloudWatchLogsClientProtocol,
        logGroupName: String,
        userIdentifier: String?,
        eventSubject: PassthroughSubject<LoggingEvent, Never>? = nil
    ) {
        self.client = client
        self.formatter = CloudWatchLoggingStreamNameFormatter(userIdentifier: userIdentifier)
        self.logGroupName = logGroupName
        self.eventSubject = eventSubject
    }

    /// The size CloudWatch attributes to these events: the UTF-8 byte length of each event's (formatted)
    /// message plus 26 bytes of per-event overhead. This is what the service limits — not the JSON size.
    private func cloudWatchByteSize(of entries: [LogEntry]) -> Int {
        entries.reduce(0) { total, entry in
            total + entryFormatter.format(entry: entry).utf8.count + CloudWatchConstants.perEventOverheadInBytes
        }
    }
}

extension CloudWatchLoggingConsumer: LogBatchConsumer {
    func consume(batch: any LogBatch) async throws {
        let rawEntries = try batch.readEntries()
        guard let entries = rawEntries as? [LogEntry], !entries.isEmpty else {
            try batch.complete()
            return
        }
        await ensureLogStreamExists()

        guard logStreamName != nil else {
            logger.error("Log stream name is nil, cannot send logs")
            try batch.complete()
            return
        }

        try await sendEntries(entries)
        try batch.complete()
    }

    private func sendEntries(_ entries: [LogEntry]) async throws {
        let batchByteSize = cloudWatchByteSize(of: entries)

        if entries.count > CloudWatchConstants.maxLogEvents {
            try await sendEntriesExceedingMaxCount(entries)
        } else if batchByteSize > Int(CloudWatchConstants.maxBatchByteSize) {
            try await sendEntriesExceedingMaxSize(entries)
        } else {
            try await sendLogEvents(entries)
        }
    }

    private func sendEntriesExceedingMaxCount(_ entries: [LogEntry]) async throws {
        let smallerEntries = entries.chunked(into: CloudWatchConstants.maxLogEvents)
        for entries in smallerEntries {
            if cloudWatchByteSize(of: entries) > Int(CloudWatchConstants.maxBatchByteSize) {
                for chunk in chunk(entries, into: Int(CloudWatchConstants.maxBatchByteSize)) {
                    try await sendLogEvents(chunk)
                }
            } else {
                try await sendLogEvents(entries)
            }
        }
    }

    private func sendEntriesExceedingMaxSize(_ entries: [LogEntry]) async throws {
        for chunk in chunk(entries, into: Int(CloudWatchConstants.maxBatchByteSize)) {
            try await sendLogEvents(chunk)
        }
    }

    private func ensureLogStreamExists() async {
        if ensureLogStreamExistsComplete {
            return
        }

        if logStreamName == nil {
            self.logStreamName = await formatter.formattedStreamName()
        }

        guard let logStreamName, !logStreamName.isEmpty else {
            logger.error("Invalid log stream name")
            ensureLogStreamExistsComplete = true
            return
        }

        let stream = try? await client.describeLogStreams(input: DescribeLogStreamsInput(
            logGroupName: logGroupName,
            logStreamNamePrefix: logStreamName
        )).logStreams?.first(where: { stream in
            return stream.logStreamName == logStreamName
        })

        if stream != nil {
            ensureLogStreamExistsComplete = true
            return
        }

        do {
            _ = try await client.createLogStream(input: CreateLogStreamInput(
                logGroupName: logGroupName,
                logStreamName: logStreamName
            ))
            ensureLogStreamExistsComplete = true
        } catch {
            // Don't latch "stream exists" when creation actually failed — leave the flag false so the
            // next flush retries. (A subsequent PutLogEvents would otherwise fail permanently.)
            logger.error("Failed to create log stream \(logStreamName): \(error)")
        }
    }

    private func sendLogEvents(_ entries: [LogEntry]) async throws {
        if entries.isEmpty { return }

        guard let logStreamName, !logStreamName.isEmpty else {
            logger.error("Cannot send log events: Log stream name is nil or empty")
            return
        }

        let events = convertToCloudWatchInputLogEvents(for: entries)
        if events.isEmpty {
            logger.warn("No valid events to send to CloudWatch")
            return
        }

        do {
            let response = try await client.putLogEvents(input: PutLogEventsInput(
                logEvents: events,
                logGroupName: logGroupName,
                logStreamName: logStreamName,
                sequenceToken: nil
            ))

            emitRejectionEventIfNeeded(response)

            let retriableEntries = retriable(entries: entries, in: response)
            if !retriableEntries.isEmpty {
                // "Too new" means the timestamp is ahead of CloudWatch's clock; retrying immediately hits
                // the same rejection, so back off briefly before re-sending.
                try await Task.sleep(nanoseconds: 1_000_000_000)
                let retriableEvents = convertToCloudWatchInputLogEvents(for: retriableEntries)
                if !retriableEvents.isEmpty {
                    _ = try await client.putLogEvents(input: PutLogEventsInput(
                        logEvents: retriableEvents,
                        logGroupName: logGroupName,
                        logStreamName: logStreamName,
                        sequenceToken: nil
                    ))
                }
            }
        } catch {
            logger.error("Failed to send log events: \(error)")
            throw CloudWatchError.service(
                "Failed to send log events to CloudWatch",
                "Please check underlying error for details.",
                error
            )
        }
    }

    private func convertToCloudWatchInputLogEvents(for entries: [LogEntry]) -> [CloudWatchLogsClientTypes.InputLogEvent] {
        return entries.map { entry in
            .init(
                message: entryFormatter.format(entry: entry),
                timestamp: entry.millisecondsSince1970
            )
        }
    }

    private func retriable(entries: [LogEntry], in response: PutLogEventsOutput) -> [LogEntry] {
        guard let tooNewLogEventStartIndex = response.rejectedLogEventsInfo?.tooNewLogEventStartIndex else {
            return []
        }
        let totalEntries = entries.count
        if tooNewLogEventStartIndex < 0 || tooNewLogEventStartIndex >= totalEntries {
            return []
        }

        var retriableEntries: [LogEntry] = []
        for index in tooNewLogEventStartIndex ..< totalEntries {
            retriableEntries.append(entries[index])
        }
        return retriableEntries
    }

    /// Surfaces genuinely undeliverable rejected events (too old / expired) rather than dropping them
    /// silently, as they can never be re-sent successfully.
    private func emitRejectionEventIfNeeded(_ response: PutLogEventsOutput) {
        guard let rejected = response.rejectedLogEventsInfo else { return }
        var undeliverable = 0
        if let tooOld = rejected.tooOldLogEventEndIndex { undeliverable = max(undeliverable, tooOld + 1) }
        if let expired = rejected.expiredLogEventEndIndex { undeliverable = max(undeliverable, expired + 1) }
        guard undeliverable > 0 else { return }
        logger.warn("\(undeliverable) log event(s) rejected by CloudWatch as too old or expired")
        eventSubject?.send(.flushLogFailure(
            context: "\(undeliverable) log event(s) were rejected by CloudWatch as too old or expired"
        ))
    }

    private func chunk(_ entries: [LogEntry], into maxByteSize: Int) -> [[LogEntry]] {
        var chunks: [[LogEntry]] = []
        var chunk: [LogEntry] = []
        var currentChunkSize = 0

        for entry in entries {
            // CloudWatch measures batch size as each event's UTF-8 message length + 26 bytes overhead —
            // the formatted message that actually ships, not the JSON encoding.
            let entrySize = entryFormatter.format(entry: entry).utf8.count + CloudWatchConstants.perEventOverheadInBytes

            // A single entry that can't fit even alone can never be sent; drop it (with an event) rather
            // than forming an over-limit chunk that CloudWatch would reject wholesale.
            if entrySize > maxByteSize {
                logger.warn("Dropping a log entry that exceeds the CloudWatch per-batch size limit")
                eventSubject?.send(.flushLogFailure(
                    context: "A log entry exceeded the CloudWatch per-batch size limit and was dropped"
                ))
                continue
            }

            if currentChunkSize + entrySize < maxByteSize {
                chunk.append(entry)
                currentChunkSize += entrySize
            } else {
                if !chunk.isEmpty {
                    chunks.append(chunk)
                }
                chunk = [entry]
                currentChunkSize = entrySize
            }
        }

        if !chunk.isEmpty {
            chunks.append(chunk)
        }

        return chunks
    }
}
