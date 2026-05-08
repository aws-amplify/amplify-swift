//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AWSCloudWatchLogs
import Foundation
import InternalCloudWatchLogging

class CloudWatchLoggingConsumer {

    private let client: CloudWatchLogsClientProtocol
    private let formatter: CloudWatchLoggingStreamNameFormatter
    private let logGroupName: String
    private var logStreamName: String?
    private var ensureLogStreamExistsComplete: Bool = false
    private let logger = AmplifyFoundation.AmplifyLogging.logger(for: CloudWatchLoggingConsumer.self)
    private let encoderLock = NSLock()
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        return encoder
    }()

    init(
        client: CloudWatchLogsClientProtocol,
        logGroupName: String,
        userIdentifier: String?
    ) {
        self.client = client
        self.formatter = CloudWatchLoggingStreamNameFormatter(userIdentifier: userIdentifier)
        self.logGroupName = logGroupName
    }

    private func safeEncode(_ value: some Encodable) throws -> Data {
        encoderLock.lock()
        defer { encoderLock.unlock() }
        return try encoder.encode(value)
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

        let entriesCopy = entries

        var batchByteSize: Int
        do {
            batchByteSize = try safeEncode(entriesCopy).count
        } catch {
            logger.error("Failed to encode log entries: \(error)")
            try batch.complete()
            return
        }

        if entriesCopy.count > CloudWatchConstants.maxLogEvents {
            let smallerEntries = entriesCopy.chunked(into: CloudWatchConstants.maxLogEvents)
            for entries in smallerEntries {
                do {
                    let entrySize = try safeEncode(entries).count
                    if entrySize > CloudWatchConstants.maxBatchByteSize {
                        let chunks = try chunk(entries, into: CloudWatchConstants.maxBatchByteSize)
                        for chunk in chunks {
                            try await sendLogEvents(chunk)
                        }
                    } else {
                        try await sendLogEvents(entries)
                    }
                } catch {
                    logger.error("Error processing log batch: \(error)")
                    continue
                }
            }
        } else if batchByteSize > CloudWatchConstants.maxBatchByteSize {
            do {
                let smallerEntries = try chunk(entriesCopy, into: CloudWatchConstants.maxBatchByteSize)
                for entries in smallerEntries {
                    try await sendLogEvents(entries)
                }
            } catch {
                logger.error("Error chunking log entries: \(error)")
            }
        } else {
            try await sendLogEvents(entriesCopy)
        }

        try batch.complete()
    }

    private func ensureLogStreamExists() async {
        if ensureLogStreamExistsComplete {
            return
        }

        if logStreamName == nil {
            let streamName = await formatter.formattedStreamName()
            if !streamName.isEmpty {
                self.logStreamName = streamName
            } else {
                self.logStreamName = "default.\(UUID().uuidString)"
            }
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

        if stream == nil {
            _ = try? await client.createLogStream(input: CreateLogStreamInput(
                logGroupName: logGroupName,
                logStreamName: logStreamName
            ))
        }

        ensureLogStreamExistsComplete = true
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

            let retriableEntries = retriable(entries: entries, in: response)
            if !retriableEntries.isEmpty {
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
            throw error
        }
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

    // swiftlint:disable shorthand_operator
    private func chunk(_ entries: [LogEntry], into maxByteSize: Int64) throws -> [[LogEntry]] {
        var chunks: [[LogEntry]] = []
        var chunk: [LogEntry] = []
        var currentChunkSize = 0

        for entry in entries {
            var entrySize: Int
            do {
                entrySize = try encoder.encode(entry).count
            } catch {
                logger.error("Failed to encode log entry: \(error)")
                continue
            }

            if currentChunkSize + entrySize < maxByteSize {
                chunk.append(entry)
                currentChunkSize = currentChunkSize + entrySize
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
    // swiftlint:enable shorthand_operator
}
