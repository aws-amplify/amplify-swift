//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SQLite
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyFoundation
@testable import AmplifyRecordCache

/// A sender whose answer the test scripts, as an async body, and which counts its calls.
private actor ScriptedSender: RecordSender {
    typealias Body = @Sendable (String, [Record]) async throws -> PutRecordsResponse

    private var body: Body
    private(set) var calls = 0

    init(_ body: @escaping Body) {
        self.body = body
    }

    func script(_ body: @escaping Body) {
        self.body = body
    }

    func putRecords(streamName: String, records: [Record]) async throws -> PutRecordsResponse {
        calls += 1
        return try await body(streamName, records)
    }
}

/// Records the level of every line the auto-flush scheduler logs while it is registered.
private final class SchedulerLogSink: LogSinkBehavior, @unchecked Sendable {
    let id = UUID().uuidString
    private let lock = NSLock()
    private var recorded: [LogLevel] = []

    var levels: [LogLevel] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func isEnabled(for logLevel: LogLevel) -> Bool {
        true
    }

    func emit(message: LogMessage) {
        guard message.name == String(describing: AutoFlushScheduler.self) else {
            return
        }
        lock.lock()
        defer { lock.unlock() }
        recorded.append(message.level)
    }
}

/// What a flush does when the credentials provider fails: `CredentialsError.disposition` decides what happens to the
/// cached records, no retry is counted, and the auto-flush backs off.
class RecordClientCredentialsFailureTests: XCTestCase, @unchecked Sendable {

    private static let accepting: ScriptedSender.Body = { _, records in
        PutRecordsResponse(successfulIds: records.map(\.id), retryableIds: [], failedIds: [])
    }

    /// A storage over the database file at `path`, or over one in memory.
    private func makeStorage(path: String? = nil) throws -> SQLiteRecordStorage {
        try SQLiteRecordStorage(
            identifier: "test_credentials",
            maxRecords: 1_000,
            cacheMaxBytes: 1_024 * 1_024,
            maxRecordSizeBytes: 10 * 1_024 * 1_024,
            maxBytesPerStream: 10 * 1_024 * 1_024,
            maxPartitionKeyLength: 256,
            connection: path.map { try Connection($0) } ?? Connection(.inMemory)
        )
    }

    private func failing(with error: CredentialsError) -> ScriptedSender {
        ScriptedSender { _, _ in throw error }
    }

    private func add(_ streamName: String, to storage: SQLiteRecordStorage) async throws {
        try await storage.addRecord(RecordInput(streamName: streamName, partitionKey: "key", data: Data([1])))
    }

    private func records(in storage: SQLiteRecordStorage) async throws -> [Record] {
        try await storage.getRecordsByStream(afterIdByStream: [:]).flatMap { $0 }
    }

    /// Polls `condition` for up to five seconds, failing the test if it never holds.
    private func waitUntil(
        _ what: String,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: @Sendable () async -> Bool
    ) async {
        for _ in 0 ..< 500 {
            if await condition() {
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("timed out waiting until \(what)", file: file, line: line)
    }

    /// The `CredentialsError` a flush threw as `RecordCacheError.credentials`, or `nil` (and a failure) otherwise.
    private func credentialsFailure(
        of client: RecordClient,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> CredentialsError? {
        do {
            _ = try await client.flush()
            XCTFail("expected the flush to throw", file: file, line: line)
        } catch RecordCacheError.credentials(let description, let suggestion, let cause) {
            let error = cause as? CredentialsError
            XCTAssertEqual(description, error?.errorDescription, file: file, line: line)
            XCTAssertEqual(suggestion, error?.recoverySuggestion, file: file, line: line)
            return error
        } catch {
            XCTFail("expected RecordCacheError.credentials, got \(error)", file: file, line: line)
        }
        return nil
    }

    // MARK: Each disposition

    /// The dispositions that keep the records: a session waiting for its user to sign in again, a transient
    /// failure, and a misconfiguration.
    ///
    /// - Given: two cached records in two streams, in a cache of the client's own, and a sender that fails with a
    ///   credentials error whose disposition is, in turn, `.retryAfterReauthentication`, `.retryWithBackoff` and
    ///   `.failLoudly`
    /// - When: the client flushes more often than `maxRetries`, then the provider recovers and it flushes again
    /// - Then:
    ///    - every failing flush throws `RecordCacheError.credentials`, with the provider's texts and its error
    ///      underneath, after asking the sender once: the second stream is not tried, and the streak counts one
    ///      failure per flush, not per stream
    ///    - both records stay, with no retry counted
    ///    - the last flush sends both
    func testTheRetryDispositionsKeepTheRecordsWithoutCountingARetry() async throws {
        let errors: [(CredentialsError, CredentialsError.Disposition)] = [
            (.sessionExpired("expired", "sign in again"), .retryAfterReauthentication),
            (.unknown("offline", "retry"), .retryWithBackoff),
            (.storageUnavailable(.locked, "locked", "retry later"), .retryWithBackoff),
            (.notConfigured("no identity pool", "configure one"), .failLoudly),
            (.storageUnavailable(.denied, "denied", "fix the entitlement"), .failLoudly)
        ]
        for (error, disposition) in errors {
            XCTAssertEqual(error.disposition, disposition)
            let storage = try makeStorage()
            try await add("stream-a", to: storage)
            try await add("stream-b", to: storage)
            let sender = failing(with: error)
            let client = RecordClient(sender: sender, storage: storage, maxRetries: 2, ownsCache: true)

            for attempt in 1 ... 4 {
                let thrown = await credentialsFailure(of: client)
                XCTAssertEqual(thrown?.errorDescription, error.errorDescription, "\(disposition), flush \(attempt)")
                let streak = await client.credentialsFailureStreak
                XCTAssertEqual(streak, attempt, "\(disposition), flush \(attempt)")
                let calls = await sender.calls
                XCTAssertEqual(calls, attempt, "\(disposition): one stream asked per flush")
            }
            let kept = try await records(in: storage)
            XCTAssertEqual(kept.count, 2, "\(disposition)")
            XCTAssertEqual(kept.map(\.retryCount), [0, 0], "\(disposition): no retry counted")

            await sender.script(Self.accepting)
            let flushed = try await client.flush()
            XCTAssertEqual(flushed.recordsFlushed, 2, "\(disposition)")
            let left = try await records(in: storage)
            XCTAssertEqual(left.count, 0, "\(disposition)")
        }
    }

    /// `.discard` (the session signed out) drops what was cached for the user who is gone, and only that.
    ///
    /// - Given: two cached records in two streams, in a cache of the client's own, and a sender that adds a third
    ///   record while it is asked, then fails with `notSignedIn`
    /// - When: the client flushes
    /// - Then:
    ///    - it throws `RecordCacheError.credentials` with the `notSignedIn` underneath
    ///    - the two records cached when the flush began are gone, in both streams, and the cache's size counts
    ///      only what is left
    ///    - the record added during the flush is kept
    func testDiscardDeletesWhatWasCachedWhenTheFlushBegan() async throws {
        let storage = try makeStorage()
        try await add("stream-a", to: storage)
        try await add("stream-b", to: storage)
        let sender = ScriptedSender { _, _ in
            try await storage.addRecord(RecordInput(streamName: "stream-a", partitionKey: "key", data: Data([9, 9])))
            throw CredentialsError.notSignedIn("signed out", "sign in first")
        }
        let client = RecordClient(sender: sender, storage: storage, ownsCache: true)

        let thrown = await credentialsFailure(of: client)

        XCTAssertEqual(thrown?.disposition, .discard)
        let kept = try await records(in: storage)
        XCTAssertEqual(kept.map(\.data), [Data([9, 9])])
        let size = try await storage.getCurrentCacheSize()
        XCTAssertEqual(size, Int64(kept[0].dataSize))
    }

    /// The region's shared cache holds every session's records, so one session's `.discard` deletes nothing.
    ///
    /// - Given: one cache file opened by two clients, neither with a cache of its own, each with one cached record
    ///   in its own stream; the first client's sender fails with `notSignedIn`, the second's accepts
    /// - When: the first client flushes, then the second
    /// - Then:
    ///    - the first throws `RecordCacheError.credentials`, and both records are still cached, with no retry counted
    ///    - the second sends both
    func testDiscardKeepsTheRecordsOfASharedCache() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).db")
        addTeardownBlock { try? FileManager.default.removeItem(at: file) }
        let signedOutStorage = try makeStorage(path: file.path)
        let otherStorage = try makeStorage(path: file.path)
        try await add("signed-out-stream", to: signedOutStorage)
        try await add("other-stream", to: otherStorage)
        let signedOut = RecordClient(
            sender: failing(with: .notSignedIn("signed out", "sign in first")),
            storage: signedOutStorage
        )
        let other = RecordClient(sender: ScriptedSender(Self.accepting), storage: otherStorage)

        let thrown = await credentialsFailure(of: signedOut)
        let kept = try await records(in: otherStorage)
        let flushed = try await other.flush()

        XCTAssertEqual(thrown?.disposition, .discard)
        XCTAssertEqual(Set(kept.map(\.streamName)), ["signed-out-stream", "other-stream"])
        XCTAssertEqual(kept.map(\.retryCount), [0, 0])
        XCTAssertEqual(flushed.recordsFlushed, 2)
    }

    // MARK: What is not a credentials failure

    /// - Given: a cached record, and a sender that fails, in turn, with a credentials error, a `CancellationError`
    ///   and a plain error
    /// - When: the client flushes after each
    /// - Then:
    ///    - the last two flushes throw the sender's error, not `RecordCacheError.credentials`
    ///    - the cancellation counts no retry and leaves the credentials-failure streak at 1
    ///    - the plain error counts one retry and ends the streak
    func testACancellationCountsNoRetryAndAnyOtherErrorCountsOne() async throws {
        struct Plain: Error {}
        let storage = try makeStorage()
        try await add("stream", to: storage)
        let sender = failing(with: .sessionExpired("expired", "sign in again"))
        let client = RecordClient(sender: sender, storage: storage)

        _ = await credentialsFailure(of: client)
        await sender.script { _, _ in throw CancellationError() }
        do {
            _ = try await client.flush()
            XCTFail("expected a cancellation")
        } catch {
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
        let afterCancellation = try await records(in: storage)
        let streakAfterCancellation = await client.credentialsFailureStreak
        await sender.script { _, _ in throw Plain() }
        do {
            _ = try await client.flush()
            XCTFail("expected the sender's error")
        } catch {
            XCTAssertTrue(error is Plain, "\(error)")
        }
        let afterFailure = try await records(in: storage)
        let streakAfterFailure = await client.credentialsFailureStreak

        XCTAssertEqual(afterCancellation.map(\.retryCount), [0])
        XCTAssertEqual(streakAfterCancellation, 1)
        XCTAssertEqual(afterFailure.map(\.retryCount), [1])
        XCTAssertEqual(streakAfterFailure, 0)
    }

    // MARK: The streak and the auto-flush's back-off

    /// - Given: a cached record and a sender that fails with `sessionExpired`
    /// - When: the client flushes three times, then the sender accepts and it flushes again; then it fails twice
    ///   more and the streak is reset
    /// - Then:
    ///    - the streak counts the failures in a row (1, 2, 3), a flush that completes ends it, and it counts
    ///      again from 1
    ///    - a reset ends it, and so does a flush with nothing to send
    func testTheStreakCountsCredentialsFailuresInARow() async throws {
        let storage = try makeStorage()
        try await add("stream", to: storage)
        let expired = CredentialsError.sessionExpired("expired", "sign in again")
        let sender = failing(with: expired)
        let client = RecordClient(sender: sender, storage: storage)

        var streaks: [Int] = []
        for _ in 1 ... 3 {
            _ = await credentialsFailure(of: client)
            streaks.append(await client.credentialsFailureStreak)
        }
        await sender.script(Self.accepting)
        _ = try await client.flush()
        streaks.append(await client.credentialsFailureStreak)
        try await add("stream", to: storage)
        await sender.script { _, _ in throw expired }
        for _ in 1 ... 2 {
            _ = await credentialsFailure(of: client)
            streaks.append(await client.credentialsFailureStreak)
        }
        await client.resetCredentialsFailureStreak()
        streaks.append(await client.credentialsFailureStreak)
        _ = await credentialsFailure(of: client)
        _ = try await storage.clearRecords()
        _ = try await client.flush()
        streaks.append(await client.credentialsFailureStreak)

        XCTAssertEqual(streaks, [1, 2, 3, 0, 1, 2, 0, 0])
    }

    /// - Given: an interval of 30 seconds, and one of an hour
    /// - When: the delay before the next flush is computed for streaks from 0 up
    /// - Then:
    ///    - with no failure it is exactly the interval
    ///    - it doubles with each failure in a row, up to 15 minutes, and stays there
    ///    - an interval longer than 15 minutes is never shortened
    func testTheDelayDoublesWithTheStreakUpToItsCap() {
        func delay(_ interval: TimeInterval, _ streak: Int) -> TimeInterval {
            AutoFlushScheduler.delay(interval: interval, credentialsFailureStreak: streak)
        }
        XCTAssertEqual((0 ... 6).map { delay(30, $0) }, [30, 60, 120, 240, 480, 900, 900])
        XCTAssertEqual(delay(30, 1_000_000), 900)
        XCTAssertEqual((0 ... 2).map { delay(3_600, $0) }, [3_600, 3_600, 3_600])
    }

    /// - Given: a scheduler with a 0.5-second interval over a client whose sender always fails with `sessionExpired`,
    ///   and a cached record
    /// - When: it runs for 4.4 seconds
    /// - Then:
    ///    - it flushed two or three times (at 0.5 s, 1.5 s and 3.5 s), not the eight a fixed interval would give
    ///    - starting a scheduler over the client again ends the streak, before any flush
    func testTheSchedulerBacksOffWhileCredentialsKeepFailing() async throws {
        let storage = try makeStorage()
        try await add("stream", to: storage)
        let sender = failing(with: .sessionExpired("expired", "sign in again"))
        let client = RecordClient(sender: sender, storage: storage)
        let scheduler = AutoFlushScheduler(interval: 0.5, recordClient: client)

        await scheduler.start()
        try await Task.sleep(nanoseconds: 4_400_000_000)
        await scheduler.disable()
        let calls = await sender.calls
        let streak = await client.credentialsFailureStreak

        XCTAssertTrue((2 ... 3).contains(calls), "flushed \(calls) times")
        XCTAssertGreaterThanOrEqual(streak, 2)

        // An hour's interval: the restart cannot flush, so only its reset can end the streak.
        let restarted = AutoFlushScheduler(interval: 3_600, recordClient: client)
        await restarted.start()
        await waitUntil("the restart ends the streak") { await client.credentialsFailureStreak == 0 }
        await restarted.disable()
        let callsAfterRestart = await sender.calls
        XCTAssertEqual(callsAfterRestart, calls)
    }

    /// - Given: a log sink, and schedulers over clients whose senders fail with `notConfigured` (`.failLoudly`) and
    ///   with `sessionExpired`, each with a cached record
    /// - When: each scheduler's first flush fails
    /// - Then:
    ///    - the misconfiguration is logged as an error: no retry will fix it
    ///    - the expired session is logged as a warning, as any other failed flush is
    func testTheSchedulerLogsAMisconfigurationAsAnError() async throws {
        let failures: [(CredentialsError, LogLevel)] = [
            (.notConfigured("no identity pool", "configure one"), .error),
            (.sessionExpired("expired", "sign in again"), .warn)
        ]
        for (error, level) in failures {
            let sink = SchedulerLogSink()
            AmplifyLogging.addSink(sink)
            defer { AmplifyLogging.removeSink(sink) }
            let storage = try makeStorage()
            try await add("stream", to: storage)
            let client = RecordClient(sender: failing(with: error), storage: storage)
            // Built after the sink is registered: a logger broadcasts to the sinks registered when it was made.
            let scheduler = AutoFlushScheduler(interval: 0.05, recordClient: client)

            await scheduler.start()
            await waitUntil("the failed flush is logged") { !sink.levels.isEmpty }
            await scheduler.disable()

            XCTAssertEqual(sink.levels.first, level, "\(error.disposition)")
        }
    }
}
