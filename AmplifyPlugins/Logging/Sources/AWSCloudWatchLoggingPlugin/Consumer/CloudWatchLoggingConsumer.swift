//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSClientRuntime
import AWSCloudWatchLogs
import AWSPluginsCore
import Foundation
import InternalCloudWatchLogging

/// - Note: `final` and `@unchecked Sendable` to satisfy `LogBatchConsumer`s `Sendable` requirement.
///   `client` comes from the AWS SDK and is not declared `Sendable`; the log stream is set up by
///   `logStreamSetup`, so batches consumed at the same time share one setup.
final class CloudWatchLoggingConsumer: @unchecked Sendable {

    private let client: CloudWatchLogsClientProtocol
    private let formatter: CloudWatchLoggingStreamNameFormatter
    private let logGroupName: String
    private let logStreamSetup = LogStreamSetup()
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
        return try encoderLock.withLock {
            return try encoder.encode(value)
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
        let logStreamName = await logStreamSetup.streamName { await self.setUpLogStream(named: $0) }

        // Create a strong reference to entries to prevent deallocation during encoding
        let entriesCopy = entries

        var batchByteSize: Int
        do {
            batchByteSize = try safeEncode(entriesCopy).count
        } catch {
            Amplify.Logging.error("Failed to encode log entries: \(error)")
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
                            try await sendLogEvents(chunk, to: logStreamName)
                        }
                    } else {
                        try await sendLogEvents(entries, to: logStreamName)
                    }
                } catch {
                    Amplify.Logging.error("Error processing log batch: \(error)")
                    continue
                }
            }
        } else if batchByteSize > CloudWatchConstants.maxBatchByteSize {
            do {
                let smallerEntries = try chunk(entriesCopy, into: CloudWatchConstants.maxBatchByteSize)
                for entries in smallerEntries {
                    try await sendLogEvents(entries, to: logStreamName)
                }
            } catch {
                Amplify.Logging.error("Error chunking log entries: \(error)")
            }
        } else {
            try await sendLogEvents(entriesCopy, to: logStreamName)
        }

        try batch.complete()
    }

    /// Resolves this consumer's stream name, unless a previous attempt did, and creates the stream if
    /// needed. `isSetUp` is false when creating it failed, so the next batch retries.
    private func setUpLogStream(named knownName: String?) async -> (name: String, isSetUp: Bool) {
        let logStreamName: String
        if let knownName {
            logStreamName = knownName
        } else {
            let streamName = await formatter.formattedStreamName()
            // Fallback to a default if the stream name couldn't be determined
            logStreamName = streamName.isEmpty ? "default.\(UUID().uuidString)" : streamName
        }

        let stream = try? await client.describeLogStreams(input: DescribeLogStreamsInput(
            logGroupName: logGroupName,
            logStreamNamePrefix: logStreamName
        )).logStreams?.first(where: { stream in
            return stream.logStreamName == logStreamName
        })

        if stream != nil {
            return (logStreamName, true)
        }

        do {
            _ = try await client.createLogStream(input: CreateLogStreamInput(
                logGroupName: logGroupName,
                logStreamName: logStreamName
            ))
            return (logStreamName, true)
        } catch {
            return (logStreamName, false)
        }
    }

    private func sendLogEvents(_ entries: [LogEntry], to logStreamName: String) async throws {
        // Safety check for empty entries
        if entries.isEmpty {
            return
        }

        // Safety check for logStreamName
        guard !logStreamName.isEmpty else {
            Amplify.Logging.error("Cannot send log events: Log stream name is nil or empty")
            return
        }

        let events = convertToCloudWatchInputLogEvents(for: entries)

        // Safety check for empty events
        if events.isEmpty {
            Amplify.Logging.warn("No valid events to send to CloudWatch")
            return
        }

        do {
            let response = try await client.putLogEvents(input: PutLogEventsInput(
                logEvents: events,
                logGroupName: logGroupName,
                logStreamName: logStreamName,
                sequenceToken: nil
            ))

            // Handle retriable entries
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
            Amplify.Logging.error("Failed to send log events: \(error)")
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
            // Wrap the encoding in a do-catch to handle potential errors
            var entrySize: Int
            do {
                entrySize = try encoder.encode(entry).count
            } catch {
                Amplify.Logging.error("Failed to encode log entry: \(error)")
                // Skip this entry and continue with the next one
                continue
            }

            if currentChunkSize + entrySize < maxByteSize {
                chunk.append(entry)
                currentChunkSize = currentChunkSize + entrySize
            } else {
                // Only add non-empty chunks
                if !chunk.isEmpty {
                    chunks.append(chunk)
                }
                chunk = [entry]
                currentChunkSize = entrySize
            }
        }

        // Add the last chunk if it's not empty
        if !chunk.isEmpty {
            chunks.append(chunk)
        }

        // Return even if chunks is empty to avoid null pointer issues
        return chunks
    }
    // swiftlint:enable shorthand_operator
}

private extension NSLock {
    func withLock<T>(_ block: () throws -> T) throws -> T {
        lock()
        defer { unlock() }
        return try block()
    }
}
