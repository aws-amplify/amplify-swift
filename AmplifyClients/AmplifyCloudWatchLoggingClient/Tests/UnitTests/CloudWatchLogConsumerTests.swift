//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AWSCloudWatchLogs
import XCTest

@testable import AmplifyCloudWatchLoggingClient
@testable import InternalCloudWatchLogging

final class CloudWatchLogConsumerTests: XCTestCase {

    var systemUnderTest: CloudWatchLoggingConsumer!
    var client: MockCloudWatchLogsClient!
    var logGroupName: String!
    var entries: [LogEntry]!
    var interactions: [String]!

    override func setUp() async throws {
        entries = []
        interactions = []
        client = MockCloudWatchLogsClient()
        logGroupName = UUID().uuidString
        systemUnderTest = CloudWatchLoggingConsumer(client: client, logGroupName: logGroupName, userIdentifier: "guest")
    }

    override func tearDown() async throws {
        entries = nil
        interactions = nil
        client = nil
        logGroupName = nil
        systemUnderTest = nil
    }

    /// - Given: a single log entry
    /// - When: CloudWatchLoggingConsumer consumes a log batch
    /// - Then: the batch is read and completed
    func testConsumerProcessValidLogBatch() async throws {
        entries = [LogEntry(namespace: "CloudWatchLogConsumerTests", level: .error, message: "")]
        try await systemUnderTest.consume(batch: self)
        XCTAssertEqual(client.interactions, [
            "describeLogStreams(input:)",
            "createLogStream(input:)",
            "putLogEvents(input:)"
        ])
        XCTAssertEqual(interactions, [
            "readEntries()",
            "complete()"
        ])
    }

    /// - Given: a list of log entries
    /// - When: CloudWatchLoggingConsumer consumes a log batch
    /// - Then: the batch is read and completed
    func testConsumerProcessValidLargeBatch() async throws {
        let batchSize = 32
        for _ in 0 ..< batchSize {
            entries.append(LogEntry(namespace: "CloudWatchLogConsumerTests", level: .error, message: ""))
        }
        try await systemUnderTest.consume(batch: self)
        XCTAssertEqual(client.interactions, [
            "describeLogStreams(input:)",
            "createLogStream(input:)",
            "putLogEvents(input:)"
        ])
        XCTAssertEqual(interactions, [
            "readEntries()",
            "complete()"
        ])
    }

    /// - Given: A list of log entries with 50% rejectable entries
    /// - When: CloudWatchLoggingConsumer consumes a log batch
    /// - Then: The batch is read and completed and the rejected entries are retried
    func testConsumerRetriesWithRejectedLogBatch() async throws {
        let batchSize = 5
        let batch = (0 ..< batchSize).map { LogEntry(namespace: "CloudWatchLogConsumerTests", level: .error, message: "\($0)", created: Date(timeIntervalSince1970: Double($0))) }
        entries.append(contentsOf: batch)

        let index = batchSize / 2
        client.putLogEventsHandler = { _ in
            return .init(
                nextSequenceToken: nil,
                rejectedLogEventsInfo: .init(tooNewLogEventStartIndex: index)
            )
        }

        try await systemUnderTest.consume(batch: self)
        XCTAssertEqual(client.interactions, [
            "describeLogStreams(input:)",
            "createLogStream(input:)",
            "putLogEvents(input:)",
            "putLogEvents(input:)"
        ])
        XCTAssertEqual(interactions, [
            "readEntries()",
            "complete()"
        ])
    }

    /// - Given: A list of log entries with client response of TooNewLogEventStartIndexOutOfBounds
    /// - When: CloudWatchLoggingConsumer consumes a log batch
    /// - Then: The batch is read and completed and the entries are retried
    func testTooNewLogEventStartIndexOutOfBoundsAreRetried() async throws {
        let batchSize = 5
        let batch = (0 ..< batchSize).map { LogEntry(namespace: "CloudWatchLogConsumerTests", level: .error, message: "\($0)", created: Date(timeIntervalSince1970: Double($0))) }
        entries.append(contentsOf: batch)

        client.putLogEventsHandler = { _ in
            return .init(
                nextSequenceToken: nil,
                rejectedLogEventsInfo: .init(tooNewLogEventStartIndex: batchSize + 1)
            )
        }

        try await systemUnderTest.consume(batch: self)
        XCTAssertEqual(client.interactions, [
            "describeLogStreams(input:)",
            "createLogStream(input:)",
            "putLogEvents(input:)"
        ])
        XCTAssertEqual(interactions, [
            "readEntries()",
            "complete()"
        ])

        client.putLogEventsHandler = { _ in
            return .init(
                nextSequenceToken: nil,
                rejectedLogEventsInfo: .init(tooNewLogEventStartIndex: -1)
            )
        }

        try await systemUnderTest.consume(batch: self)
        XCTAssertEqual(client.interactions, [
            "describeLogStreams(input:)",
            "createLogStream(input:)",
            "putLogEvents(input:)",
            "putLogEvents(input:)"
        ])
        XCTAssertEqual(interactions, [
            "readEntries()",
            "complete()",
            "readEntries()",
            "complete()",
        ])
    }

    /// - Given: A list of log events that have expired
    /// - When: The server responds with expiredLogEventEndIndex = 0
    /// - Then: The batch is completed with an empty list of retriable entries
    func testBatchExpired() async throws {
        let batchSize = 5
        let batch = (0 ..< batchSize).map { LogEntry(namespace: "CloudWatchLogConsumerTests", level: .error, message: "\($0)", created: Date(timeIntervalSince1970: Double($0))) }
        entries.append(contentsOf: batch)

        client.putLogEventsHandler = { _ in
            return .init(
                nextSequenceToken: nil,
                rejectedLogEventsInfo: .init(expiredLogEventEndIndex: 0)
            )
        }

        try await systemUnderTest.consume(batch: self)
        XCTAssertEqual(client.interactions, [
            "describeLogStreams(input:)",
            "createLogStream(input:)",
            "putLogEvents(input:)"
        ])
        XCTAssertEqual(interactions, [
            "readEntries()",
            "complete()"
        ])
    }

    /// - Given: A list of log events that are too old
    /// - When: The server responds with tooOldLogEventEndIndex = 0
    /// - Then: The batch is completed with an empty list of retriable entries
    func testBatchTooOld() async throws {
        let batchSize = 5
        let batch = (0 ..< batchSize).map { LogEntry(namespace: "CloudWatchLogConsumerTests", level: .error, message: "\($0)", created: Date(timeIntervalSince1970: Double($0))) }
        entries.append(contentsOf: batch)

        client.putLogEventsHandler = { _ in
            return .init(
                nextSequenceToken: nil,
                rejectedLogEventsInfo: .init(tooOldLogEventEndIndex: 0)
            )
        }

        try await systemUnderTest.consume(batch: self)
        XCTAssertEqual(client.interactions, [
            "describeLogStreams(input:)",
            "createLogStream(input:)",
            "putLogEvents(input:)"
        ])
        XCTAssertEqual(interactions, [
            "readEntries()",
            "complete()"
        ])
    }

    /// Given: An empty batch
    /// When: An attempt to consume it takes place
    /// Then: No calls to the underlying client are made
    func testEmptyFile() async throws {
        try await systemUnderTest.consume(batch: self)
        XCTAssertEqual(client.interactions, [])
        XCTAssertEqual(interactions, [
            "readEntries()",
            "complete()"
        ])
    }

    /// Given: an entry that results in a client error
    /// When: An attempt to consume it takes place
    /// Then: an exception is thrown
    func testClientThrowsOnClientError() async throws {
        enum TestError: Error {
            case consumeError
        }
        client.putLogEventsHandler = { _ in
            throw TestError.consumeError
        }
        entries.append(LogEntry(namespace: "CloudWatchLogConsumerTests", level: .error, message: ""))
        do {
            _ = try await systemUnderTest.consume(batch: self)
            XCTFail("Expecting exception propagated from mock client.")
        } catch {
            XCTAssertEqual(String(describing: error), "consumeError")
        }
        XCTAssertEqual(client.interactions, [
            "describeLogStreams(input:)",
            "createLogStream(input:)",
            "putLogEvents(input:)"
        ])
        XCTAssertEqual(interactions, [
            "readEntries()",
        ])
    }

    /// - Given: a list of log entries bigger than the maximum putLogEvents size limit
    /// - When: CloudWatchLoggingConsumer consumes a log batch
    /// - Then: the batch is chunked into entries under the size limit and sent
    func testConsumerChunkBatchesBasedOnMaxSize() async throws {
        let batchSize = 5
        let bytesPerLogMessage = 300_000
        let bytes = (0 ..< bytesPerLogMessage).map { _ in UInt8.random(in: 0 ..< 255) }
        let data = Data(bytes)

        for index in 0 ..< batchSize {
            entries.append(LogEntry(namespace: String(index), level: .error, message: data.base64EncodedString()))
        }
        try await systemUnderTest.consume(batch: self)
        XCTAssertEqual(client.interactions, [
            "describeLogStreams(input:)",
            "createLogStream(input:)",
            "putLogEvents(input:)",
            "putLogEvents(input:)",
            "putLogEvents(input:)"
        ])
        XCTAssertEqual(interactions, [
            "readEntries()",
            "complete()"
        ])
    }

    /// - Given: a list of log entries bigger than the maximum putLogEvents count limit
    /// - When: CloudWatchLoggingConsumer consumes a log batch
    /// - Then: the batch is chunked into entries under the count limit and sent
    func testConsumerChunkBatchesBasedOnMaxCount() async throws {
        let batchSize = 12_000
        let batch = (0 ..< batchSize).map { LogEntry(namespace: "CloudWatchLogConsumerTests", level: .error, message: "\($0)", created: Date(timeIntervalSince1970: Double($0))) }
        entries.append(contentsOf: batch)

        try await systemUnderTest.consume(batch: self)
        XCTAssertEqual(client.interactions, [
            "describeLogStreams(input:)",
            "createLogStream(input:)",
            "putLogEvents(input:)",
            "putLogEvents(input:)",
        ])
        XCTAssertEqual(interactions, [
            "readEntries()",
            "complete()"
        ])
    }
}

extension CloudWatchLogConsumerTests: LogBatch {

    func readEntries() throws -> [any LogEntryRepresentable] {
        interactions.append(#function)
        return entries
    }

    func complete() {
        interactions.append(#function)
    }
}
