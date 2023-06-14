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
    var unprocessed: [LogEntry]!
    var interactions: [String]!
    
    override func setUp() async throws {
        entries = []
        unprocessed = []
        interactions = []
        client = MockCloudWatchLogsClient()
        logGroupName = UUID().uuidString
        logStreamName = UUID().uuidString
        systemUnderTest = try CloudWatchLoggingConsumer(client: client, logGroupName: logGroupName, userIdentifier: "guest")
    }
    
    override func tearDown() async throws {
        entries = nil
        unprocessed = nil
        interactions = nil
        client = nil
        logGroupName = nil
        logStreamName = nil
        systemUnderTest = nil
    }
    
    func testSingleEntryHappyPath() async throws {
        self.entries = [LogEntry(tag: "CloudWatchLogConsumerTests", level: .error, message: "")]
        try await systemUnderTest.consume(batch: self)
        XCTAssertEqual(client.interactions, [
            "describeLogStreams(input:)",
            "createLogStream(input:)",
            "putLogEvents(input:)"
        ])
        XCTAssertEqual(interactions, [
            "readEntries()",
            "complete(with:)"
        ])
        XCTAssertEqual(unprocessed, [
        ])
    }
    
    func testBatchHappyPath() async throws {
        let batchSize = 32
        for _ in 0..<batchSize {
            self.entries.append(contentsOf: [LogEntry(tag: "CloudWatchLogConsumerTests", level: .error, message: "")])
        }
        try await systemUnderTest.consume(batch: self)
        XCTAssertEqual(client.interactions, [
            "describeLogStreams(input:)",
            "createLogStream(input:)",
            "putLogEvents(input:)"
        ])
        XCTAssertEqual(interactions, [
            "readEntries()",
            "complete(with:)"
        ])
        XCTAssertEqual(unprocessed, [
        ])
    }
    
    func testBatchHalfRetriable() async throws {
        let batchSize = 5
        let batch = (0..<batchSize).map { LogEntry(tag: "CloudWatchLogConsumerTests", level: .error, message: "\($0)", created: Date(timeIntervalSince1970: Double($0))) }
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
            "putLogEvents(input:)"
        ])
        XCTAssertEqual(interactions, [
            "readEntries()",
            "complete(with:)"
        ])
        XCTAssertEqual(unprocessed, Array(batch.suffix(from: index)))
    }
    
    func testTooNewLogEventStartIndexOutOfBounds() async throws {
        let batchSize = 5
        let batch = (0..<batchSize).map { LogEntry(tag: "CloudWatchLogConsumerTests", level: .error, message: "\($0)", created: Date(timeIntervalSince1970: Double($0))) }
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
            "complete(with:)"
        ])
        XCTAssertEqual(unprocessed, [
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
            "complete(with:)",
            "readEntries()",
            "complete(with:)",
        ])
        XCTAssertEqual(unprocessed, [
        ])
    }
    
    /// - Given: A list of log events that are have expired
    /// - When: The server responds with expiredLogEventEndIndex = 0
    /// - Then: The batch is completed with an empty list of retriable entries
    func testBatchExpired() async throws {
        let batchSize = 5
        let batch = (0..<batchSize).map { LogEntry(tag: "CloudWatchLogConsumerTests", level: .error, message: "\($0)", created: Date(timeIntervalSince1970: Double($0))) }
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
            "complete(with:)"
        ])
        XCTAssertEqual(unprocessed, [
        ])
    }
    
    /// - Given: A list of log events that are have expired
    /// - When: The server responds with tooOldLogEventEndIndex = 0
    /// - Then: The batch is completed with an empty list of retriable entries
    func testBatchTooOld() async throws {
        let batchSize = 5
        let batch = (0..<batchSize).map { LogEntry(tag: "CloudWatchLogConsumerTests", level: .error, message: "\($0)", created: Date(timeIntervalSince1970: Double($0))) }
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
            "complete(with:)"
        ])
        XCTAssertEqual(unprocessed, [
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
            "complete(with:)"
        ])
        XCTAssertEqual(unprocessed, [
        ])
    }
    
    func testClientThrows() async throws {
        enum TestError: Error {
            case consumeError
        }
        client.putLogEventsHandler = { _ in
            throw TestError.consumeError
        }
        self.entries.append(LogEntry(tag: "CloudWatchLogConsumerTests", level: .error, message: ""))
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
        XCTAssertEqual(unprocessed, [
        ])
    }
}

extension CloudWatchLogConsumerTests: LogBatch {

    func readEntries() throws -> [LogEntry] {
        interactions.append(#function)
        return entries
    }
    
    func complete(with unprocessed: [LogEntry]) {
        interactions.append(#function)
        self.unprocessed.append(contentsOf: unprocessed)
    }
    
}
