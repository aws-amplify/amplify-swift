//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCloudWatchLogs
import Foundation
import XCTest

@testable import AWSCloudWatchLoggingPlugin
@testable import InternalCloudWatchLogging

extension CloudWatchLogConsumerTests {

    /// - Given: a consumer that hasn't set up its log stream yet
    /// - When: several log batches are consumed at the same time
    /// - Then: the log stream is described and created once, and every batch is sent to that stream
    func testConcurrentConsumesSetUpLogStreamOnce() async throws {
        client.describeLogStreamsHandler = { _ in
            // Keeps the first setup in flight while the other batches arrive.
            try await Task.sleep(nanoseconds: 100_000_000)
            return DescribeLogStreamsOutput()
        }
        let streamNames = AtomicValue<[String]>(initialValue: [])
        client.putLogEventsHandler = { input in
            streamNames.append(input.logStreamName ?? "")
            return PutLogEventsOutput()
        }
        let consumer = systemUnderTest!
        let batches = (0 ..< 8).map { index in
            TestLogBatch(entries: [
                LogEntry(category: "CloudWatchLogConsumerTests", namespace: nil, level: .error, message: "\(index)")
            ])
        }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for batch in batches {
                group.addTask { try await consumer.consume(batch: batch) }
            }
            try await group.waitForAll()
        }

        XCTAssertEqual(client.interactions.count(where: { $0 == "describeLogStreams(input:)" }), 1)
        XCTAssertEqual(client.interactions.count(where: { $0 == "createLogStream(input:)" }), 1)
        XCTAssertEqual(streamNames.get().count, batches.count)
        XCTAssertEqual(Set(streamNames.get()).count, 1)
    }

    /// - Given: a consumer whose first attempt to create its log stream fails
    /// - When: three log batches are consumed one after another
    /// - Then: the second batch sets up the log stream again, and the third reuses it
    func testFailedLogStreamCreationIsRetriedOnNextBatch() async throws {
        let createAttempts = AtomicValue(initialValue: 0)
        client.createLogStreamHandler = { _ in
            if createAttempts.increment() == 1 {
                throw MockCloudWatchLogsClient.MockError.unexpected
            }
            return CreateLogStreamOutput()
        }
        let batch = TestLogBatch(entries: [
            LogEntry(category: "CloudWatchLogConsumerTests", namespace: nil, level: .error, message: "")
        ])

        try await systemUnderTest.consume(batch: batch)
        try await systemUnderTest.consume(batch: batch)
        try await systemUnderTest.consume(batch: batch)

        XCTAssertEqual(client.interactions, [
            "describeLogStreams(input:)",
            "createLogStream(input:)",
            "putLogEvents(input:)",
            "describeLogStreams(input:)",
            "createLogStream(input:)",
            "putLogEvents(input:)",
            "putLogEvents(input:)"
        ])
    }
}

private struct TestLogBatch: LogBatch {
    let entries: [LogEntry]

    func readEntries() throws -> [any LogEntryRepresentable] {
        entries
    }

    func complete() {}
}
