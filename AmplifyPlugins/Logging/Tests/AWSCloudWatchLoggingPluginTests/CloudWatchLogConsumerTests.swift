//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCloudWatchLogs
import Amplify
import Foundation
import XCTest

@testable import AWSCloudWatchLoggingPlugin

final class CloudWatchLogConsumerTests: XCTestCase {
    
    var systemUnderTest: CloudWatchLoggingConsumer!
    var client: MockCloudWatchLogsClient!
    var logGroupName: String!
    var logStreamName: String!
    var entries: [LogEntry]!
    var interactions: [String]!
    
    override func setUp() async throws {
        entries = []
        interactions = []
        client = MockCloudWatchLogsClient()
        logGroupName = UUID().uuidString
        logStreamName = UUID().uuidString
        systemUnderTest = try CloudWatchLoggingConsumer(client: client, logGroupName: logGroupName, userIdentifier: "guest")
    }
    
    override func tearDown() async throws {
        entries = nil
        interactions = nil
        client = nil
        logGroupName = nil
        logStreamName = nil
        systemUnderTest = nil
    }
    
    /// - Given: a single log entry
    /// - When: CloudWatchLoggingConsumer consumes a log batch
    /// - Then: the batch is read and completed
    func testConsumerProcessValidLogBatch() async throws {
        self.entries = [LogEntry(category: "CloudWatchLogConsumerTests", namespace:nil, level: .error, message: "")]
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
        for _ in 0..<batchSize {
            self.entries.append(contentsOf: [LogEntry(category: "CloudWatchLogConsumerTests", namespace:nil, level: .error, message: "")])
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
        let batch = (0..<batchSize).map { LogEntry(category: "CloudWatchLogConsumerTests", namespace:nil, level: .error, message: "\($0)", created: Date(timeIntervalSince1970: Double($0))) }
        self.entries.append(contentsOf: batch)

        let index = batchSize/2
        client.putLogEventsHandler = { _ in
            return .init(
                nextSequenceToken: nil,
                rejectedLogEventsInfo: .init(
                    tooNewLogEventStartIndex: index
                )
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
        let batch = (0..<batchSize).map { LogEntry(category: "CloudWatchLogConsumerTests", namespace:nil, level: .error, message: "\($0)", created: Date(timeIntervalSince1970: Double($0))) }
        self.entries.append(contentsOf: batch)

        client.putLogEventsHandler = { _ in
            return .init(
                nextSequenceToken: nil,
                rejectedLogEventsInfo: .init(
                    tooNewLogEventStartIndex: batchSize + 1
                )
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
                rejectedLogEventsInfo: .init(
                    tooNewLogEventStartIndex: -1
                )
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
    
    /// - Given: A list of log events that are have expired
    /// - When: The server responds with expiredLogEventEndIndex = 0
    /// - Then: The batch is completed with an empty list of retriable entries
    func testBatchExpired() async throws {
        let batchSize = 5
        let batch = (0..<batchSize).map { LogEntry(category: "CloudWatchLogConsumerTests", namespace:nil, level: .error, message: "\($0)", created: Date(timeIntervalSince1970: Double($0))) }
        self.entries.append(contentsOf: batch)

        // Simulating a response indicating that all entries from index 0 are
        // expired.
        client.putLogEventsHandler = { _ in
            return .init(
                nextSequenceToken: nil,
                rejectedLogEventsInfo: .init(
                    expiredLogEventEndIndex: 0
                )
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
    
    /// - Given: A list of log events that are have expired
    /// - When: The server responds with tooOldLogEventEndIndex = 0
    /// - Then: The batch is completed with an empty list of retriable entries
    func testBatchTooOld() async throws {
        let batchSize = 5
        let batch = (0..<batchSize).map { LogEntry(category: "CloudWatchLogConsumerTests", namespace:nil, level: .error, message: "\($0)", created: Date(timeIntervalSince1970: Double($0))) }
        self.entries.append(contentsOf: batch)
        
        client.putLogEventsHandler = { _ in
            return .init(
                nextSequenceToken: nil,
                rejectedLogEventsInfo: .init(
                    tooOldLogEventEndIndex: 0
                )
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
        client.putLogEventsHandler = { _ in
            return .init(
                nextSequenceToken: nil,
                rejectedLogEventsInfo: nil
            )
        }
        try await systemUnderTest.consume(batch: self)
        XCTAssertEqual(client.interactions, [
        ])
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
        self.entries.append(LogEntry(category: "CloudWatchLogConsumerTests", namespace: nil, level: .error, message: ""))
        do {
            let _ = try await systemUnderTest.consume(batch: self)
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
}

extension CloudWatchLogConsumerTests: LogBatch {

    func readEntries() throws -> [LogEntry] {
        interactions.append(#function)
        return entries
    }
    
    func complete() {
        interactions.append(#function)
    }
    
}
