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

class CloudWatchLoggingConsumer {

    private let client: CloudWatchLogsClientProtocol
    private let formatter: CloudWatchLoggingStreamNameFormatter
    private let logGroupName: String
    private var logStreamName: String?
    private var ensureLogStreamExistsComplete: Bool = false
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

    private func safeEncode<T: Encodable>(_ value: T) throws -> Data {
        return try encoderLock.withLock {
            return try encoder.encode(value)
        }
    }
}

extension CloudWatchLoggingConsumer: LogBatchConsumer {
    func consume(batch: LogBatch) async throws {
        let entries = try batch.readEntries()
        if entries.isEmpty {
            try batch.complete()
            return
        }
        await ensureLogStreamExists()

        // Add safety check for nil logStreamName
        guard let _ = self.logStreamName else {
            Amplify.Logging.error("Log stream name is nil, cannot send logs")
            try batch.complete()
            return
        }

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
        
        if entriesCopy.count > AWSCloudWatchConstants.maxLogEvents {
            let smallerEntries = entriesCopy.chunked(into: AWSCloudWatchConstants.maxLogEvents)
            for entries in smallerEntries {
                do {
                    let entrySize = try safeEncode(entries).count
                    if entrySize > AWSCloudWatchConstants.maxBatchByteSize {
                        let chunks = try chunk(entries, into: AWSCloudWatchConstants.maxBatchByteSize)
                        for chunk in chunks {
                            try await sendLogEvents(chunk)
                        }
                    } else {
                        try await sendLogEvents(entries)
                    }
                } catch {
                    Amplify.Logging.error("Error processing log batch: \(error)")
                    continue
                }
            }
        } else if batchByteSize > AWSCloudWatchConstants.maxBatchByteSize {
            do {
                let smallerEntries = try chunk(entriesCopy, into: AWSCloudWatchConstants.maxBatchByteSize)
                for entries in smallerEntries {
                    try await sendLogEvents(entries)
                }
            } catch {
                Amplify.Logging.error("Error chunking log entries: \(error)")
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

        // Only mark as complete after everything has finished successfully
        // to avoid potential race conditions with incomplete state
        
        if logStreamName == nil {
            do {
                // Explicitly capture self to avoid potential memory issues
                let streamName = await self.formatter.formattedStreamName()
                // Check if self is still valid and streamName is not nil before assigning
                if !streamName.isEmpty {
                    self.logStreamName = streamName
                } else {
                    // Fallback to a default if the stream name couldn't be determined
                    self.logStreamName = "default.\(UUID().uuidString)"
                }
            } catch {
                // Handle any potential errors from async call
                Amplify.Logging.error("Failed to get formatted stream name: \(error)")
                // Fallback to a default
                self.logStreamName = "default.\(UUID().uuidString)"
            }
        }
        
        // Safety check - ensure we have a valid stream name before proceeding
        guard let logStreamName = self.logStreamName, !logStreamName.isEmpty else {
            Amplify.Logging.error("Invalid log stream name")
            ensureLogStreamExistsComplete = true
            return
        }
        
        do {
            let stream = try? await self.client.describeLogStreams(input: DescribeLogStreamsInput(
                logGroupName: self.logGroupName,
                logStreamNamePrefix: logStreamName
            )).logStreams?.first(where: { stream in
                return stream.logStreamName == logStreamName
            })
            
            if stream == nil {
                _ = try? await self.client.createLogStream(input: CreateLogStreamInput(
                    logGroupName: self.logGroupName,
                    logStreamName: logStreamName
                ))
            }
            
            // Mark as complete only after all operations finished
            ensureLogStreamExistsComplete = true
        } catch {
            Amplify.Logging.error("Error ensuring log stream exists: \(error)")
            // Still mark as complete to avoid getting stuck in a failed state
            ensureLogStreamExistsComplete = true
        }
    }

    private func sendLogEvents(_ entries: [LogEntry]) async throws {
        // Safety check for empty entries
        if entries.isEmpty {
            return
        }
        
        // Safety check for logStreamName
        guard let logStreamName = self.logStreamName, !logStreamName.isEmpty else {
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
            let response = try await self.client.putLogEvents(input: PutLogEventsInput(
                logEvents: events,
                logGroupName: self.logGroupName,
                logStreamName: logStreamName,
                sequenceToken: nil
            ))
            
            // Handle retriable entries
            let retriableEntries = retriable(entries: entries, in: response)
            if !retriableEntries.isEmpty {
                let retriableEvents = convertToCloudWatchInputLogEvents(for: retriableEntries)
                if !retriableEvents.isEmpty {
                    _ = try await self.client.putLogEvents(input: PutLogEventsInput(
                        logEvents: retriableEvents,
                        logGroupName: self.logGroupName,
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
        for index in tooNewLogEventStartIndex..<totalEntries {
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


