//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
@preconcurrency import Combine
import XCTest

@testable import AmplifyCloudWatchClient
@testable import InternalCloudWatchLogging

final class RotatingLoggerTests: XCTestCase {

    var systemUnderTest: RotatingLogger!
    var directory: URL!
    var fileSizeLimitInBytes = 1_024
    var subscription: Combine.Cancellable! { willSet { subscription?.cancel() } }
    var batches: [any LogBatch]!

    override func setUp() async throws {
        directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        systemUnderTest = try RotatingLogger(
            directory: directory,
            namespace: "RotatingLoggerTests",
            fileSizeLimitInBytes: fileSizeLimitInBytes
        )
        batches = []
        subscription = systemUnderTest.logBatchPublisher.sink(receiveValue: { [weak self] in self?.batches.append($0) })
    }

    override func tearDown() async throws {
        systemUnderTest = nil
        subscription = nil
        batches = nil
        try FileManager.default.removeItem(at: directory)
        directory = nil
    }

    /// Given: a rotating logger
    /// When: a record is written
    /// Then: a log file is created
    func testRotatingLogRecordsToLogFile() async throws {
        let minimalSizeOfEachRecord = try LogEntry.minimumSizeForLogEntry(level: .error)
        let recordsPerFile = Int(fileSizeLimitInBytes) / minimalSizeOfEachRecord
        for _ in 0 ..< (recordsPerFile + 1) {
            try await systemUnderTest.record(level: .error, message: "")
        }
        try await systemUnderTest.synchronize()
        XCTAssertEqual(batches.compactMap { ($0 as? RotatingLogBatch)?.testFileName }, [
            "amplify.0.log"
        ])
    }

    /// Given: a rotating logger
    /// When: error is recorded
    /// Then: the error and error message is written
    func testLoggerLogsError() async throws {
        struct TestError: Error, CustomStringConvertible {
            var message: String = UUID().uuidString
            var description: String { return message }
        }
        let error = TestError()
        systemUnderTest.error(error: error)
        try await systemUnderTest.synchronize()
        try await Task.sleep(seconds: 0.100)
        try assertSingleEntryWith(level: .error, message: error.message)
    }

    /// Given: a rotating logger
    /// When: error message is recorded
    /// Then: the log level and message is written
    func testLoggerLogsErrorMessage() async throws {
        let level = LogLevel.error
        let message = UUID().uuidString
        try await logWith(level: level, message: message)
        try assertSingleEntryWith(level: level, message: message)
    }

    /// Given: a rotating logger
    /// When: verbose message is recorded
    /// Then: the log level and message is written
    func testLoggerLogsVerboseMessage() async throws {
        let level = LogLevel.verbose
        let message = UUID().uuidString
        try await logWith(level: level, message: message)
        try assertSingleEntryWith(level: level, message: message)
    }

    /// Given: a rotating logger
    /// When: warn message is recorded
    /// Then: the log level and message is written
    func testLoggerLogsWarnMessage() async throws {
        let level = LogLevel.warn
        let message = UUID().uuidString
        try await logWith(level: level, message: message)
        try assertSingleEntryWith(level: level, message: message)
    }

    /// Given: a rotating logger
    /// When: info message is recorded
    /// Then: the log level and message is written
    func testLoggerLogsInfoMessage() async throws {
        let level = LogLevel.info
        let message = UUID().uuidString
        try await logWith(level: level, message: message)
        try assertSingleEntryWith(level: level, message: message)
    }

    /// Given: a rotating logger
    /// When: debug message is recorded
    /// Then: the log level and message is written
    func testLoggerLogsDebugMessage() async throws {
        let level = LogLevel.debug
        let message = UUID().uuidString
        try await logWith(level: level, message: message)
        try assertSingleEntryWith(level: level, message: message)
    }

    /// Given: a rotating logger with 1 existing log batch
    /// When: get log batch is called after writing and rotating to new log file
    /// Then: a list of log batches with a count of 2 is returned
    func testRotatingLogReturnsLogBatches() async throws {
        var logBatches = try await systemUnderTest.getLogBatches()
        XCTAssertEqual(logBatches.count, 1)
        let size = try LogEntry.minimumSizeForLogEntry(level: .error)
        let recordsPerFile = (fileSizeLimitInBytes / size)
        for _ in 0 ..< recordsPerFile {
            try await systemUnderTest.record(level: .error, message: "Test message")
        }
        try await systemUnderTest.synchronize()
        logBatches = try await systemUnderTest.getLogBatches()
        XCTAssertEqual(logBatches.count, 2)
    }

    /// Given: an entry in the active log file
    /// When: a flush batch is sealed, another entry is written before the sealed batch is completed
    ///       (its file deleted), and the sealed batch is then completed
    /// Then: the entry written after the seal is not deleted with the sealed file — it survives to the
    ///       next flush. Guards the seal-before-ship fix for the concurrent-write-during-flush race.
    func testFlushDoesNotDropWritesArrivingBeforeBatchCompletion() async throws {
        try await systemUnderTest.record(level: .error, message: "A")
        try await systemUnderTest.synchronize()

        let sealedBatches = try await systemUnderTest.getFlushableLogBatches()

        // Written after the seal: with seal-before-ship this lands in the fresh active file, not the
        // sealed one about to be deleted.
        try await systemUnderTest.record(level: .error, message: "B")
        try await systemUnderTest.synchronize()

        var shipped: [String] = []
        for batch in sealedBatches {
            shipped.append(contentsOf: try batch.readEntries().map { $0.message })
            try batch.complete()
        }

        let drained = try await performFlush()
        XCTAssertEqual(shipped, ["A"], "The sealed batch should contain the pre-flush entry")
        XCTAssertEqual(drained, ["B"], "An entry written after the seal must survive the flush")
    }

    /// Given: a seeded active log file
    /// When: many entries are written concurrently with a flush
    /// Then: every entry is accounted for across the flushes — none is dropped
    func testConcurrentWritesDuringFlushAreNotDropped() async throws {
        try await systemUnderTest.record(level: .error, message: "seed")
        try await systemUnderTest.synchronize()

        let messageCount = 10
        async let writes: Void = {
            for index in 0 ..< messageCount {
                try await systemUnderTest.record(level: .error, message: "concurrent-\(index)")
            }
        }()
        let shippedDuringFlush = try await performFlush()
        try await writes
        try await systemUnderTest.synchronize()
        let shippedAfter = try await performFlush()

        let all = Set(shippedDuringFlush + shippedAfter)
        var expected: Set<String> = ["seed"]
        for index in 0 ..< messageCount { expected.insert("concurrent-\(index)") }
        XCTAssertEqual(all, expected, "No log entry written around a flush should be dropped")
    }

    /// Seals and ships the currently flushable batches the way the consumer does — read every entry,
    /// then delete the batch file — and returns the shipped messages.
    @discardableResult
    private func performFlush() async throws -> [String] {
        let batches = try await systemUnderTest.getFlushableLogBatches()
        var messages: [String] = []
        for batch in batches {
            messages.append(contentsOf: try batch.readEntries().map { $0.message })
            try batch.complete()
        }
        return messages
    }

    private func logWith(level: LogLevel, message: String) async throws {
        switch level {
        case .error:
            systemUnderTest.error(message)
        case .verbose:
            systemUnderTest.verbose(message)
        case .warn:
            systemUnderTest.warn(message)
        case .info:
            systemUnderTest.info(message)
        case .debug:
            systemUnderTest.debug(message)
        case .none:
            break
        }
        try await systemUnderTest.synchronize()
        try await Task.sleep(seconds: 0.100)
    }

    private func assertSingleEntryWith(level: LogLevel, message: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970

        let fileURL = try XCTUnwrap(FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil).first)
        let contents = try XCTUnwrap(FileManager.default.contents(atPath: fileURL.path))
        let entry = try decoder.decode(LogEntry.self, from: contents)
        XCTAssertEqual(entry.logLevel, level, file: file, line: line)
        XCTAssertEqual(entry.message, message, file: file, line: line)
        XCTAssertNotNil(entry.created, file: file, line: line)
    }
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let nanoseconds = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}
