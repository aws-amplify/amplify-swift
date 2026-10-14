//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCloudWatchLogs
import Combine
import CryptoKit
import XCTest

@testable import AmplifyFoundation

@_spi(AmplifyExperimental) @testable import AmplifyCloudWatchClient
@testable import InternalCloudWatchLogging

final class CloudWatchLoggingSessionControllerTests: XCTestCase {

    var systemUnderTest: CloudWatchLoggingSessionController!
    let mockCloudWatchLogClient = MockCloudWatchLogsClient()
    let mockLoggingNetworkMonitor = MockLoggingNetworkMonitor()
    let namespace = "amplifytest"
    var eventSubject: PassthroughSubject<LoggingEvent, Never>!
    var eventSubscription: AnyCancellable?

    override func setUp() async throws {
        eventSubject = PassthroughSubject<LoggingEvent, Never>()
    }

    override func tearDown() async throws {
        systemUnderTest = nil
        eventSubscription = nil
        eventSubject = nil
    }

    /// Given: a CloudWatchLoggingSessionController
    /// When: a flush log is called and the CloudWatch client fails
    /// Then: a flushLogFailure event is published to the event subject
    func testConsumeFailureSendsEvent() async throws {
        let eventExpectation = expectation(description: "Should receive the flush failure event")
        // A failed batch is now retained for retry (not deleted), so the failure event can fire on more
        // than one flush attempt. We only need to confirm it is emitted at least once.
        eventExpectation.assertForOverFulfill = false
        eventSubscription = eventSubject.sink { event in
            switch event {
            case .flushLogFailure:
                eventExpectation.fulfill()
            default:
                break
            }
        }

        // Make the mock client throw to trigger a flush failure
        mockCloudWatchLogClient.putLogEventsHandler = { _ in
            throw MockCloudWatchLogsClient.MockError.unexpected
        }

        systemUnderTest = CloudWatchLoggingSessionController(
            client: mockCloudWatchLogClient,
            logFilter: MockLoggingFilter(),
            namespace: namespace,
            logGroupName: "logGroupName",
            region: "us-east-1",
            localStoreMaxSizeInMB: 1,
            userIdentifier: nil,
            networkMonitor: mockLoggingNetworkMonitor,
            eventSubject: eventSubject
        )
        systemUnderTest.enable()

        // Log an entry through the controller so there's data to flush.
        systemUnderTest.log(.error, "test error message", nil)

        // The write is async and fire-and-forget, so flush repeatedly in the background until it has
        // landed and the failure surfaces — deterministic and bounded, rather than a single fixed sleep.
        let controller = systemUnderTest!
        let flushLoop = Task {
            while !Task.isCancelled {
                try? await controller.flushLogs()
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
        await fulfillment(of: [eventExpectation], timeout: 10)
        flushLoop.cancel()
    }

    /// Given: a controller whose network monitor reports offline
    /// When: flushLogs() is called
    /// Then: no calls are made to CloudWatch (logs are retained for a later, online flush)
    func testFlushLogsSkippedWhenOffline() async throws {
        mockLoggingNetworkMonitor.isOnline = false
        mockCloudWatchLogClient.putLogEventsHandler = { _ in
            XCTFail("flushLogs must not send while offline")
            return PutLogEventsOutput()
        }
        systemUnderTest = CloudWatchLoggingSessionController(
            client: mockCloudWatchLogClient,
            logFilter: MockLoggingFilter(),
            namespace: namespace,
            logGroupName: "logGroupName",
            region: "us-east-1",
            localStoreMaxSizeInMB: 1,
            userIdentifier: nil,
            networkMonitor: mockLoggingNetworkMonitor,
            eventSubject: eventSubject
        )
        systemUnderTest.enable()
        systemUnderTest.log(.error, "test error message", nil)
        try await Task.sleep(nanoseconds: 300_000_000)

        try await systemUnderTest.flushLogs()

        XCTAssertTrue(mockCloudWatchLogClient.interactions.isEmpty, "No client calls should occur while offline")
    }

    /// Changing the user while disabled
    ///
    /// - Given: a controller that was enabled and then disabled
    /// - When:
    ///    - the current user changes
    /// - Then:
    ///    - no session is created for the new user until the controller is enabled again
    ///
    func testUserChangeWhileDisabledDoesNotCreateSession() throws {
        let userIdentifier = "user-\(UUID().uuidString)"
        let userDirectory = logDirectory(forUser: userIdentifier)
        defer { try? FileManager.default.removeItem(at: userDirectory.deletingLastPathComponent()) }
        systemUnderTest = makeController(userIdentifier: nil)
        systemUnderTest.enable()
        systemUnderTest.disable()

        systemUnderTest.setCurrentUser(identifier: userIdentifier)
        XCTAssertFalse(FileManager.default.fileExists(atPath: userDirectory.path))

        systemUnderTest.enable()
        XCTAssertTrue(FileManager.default.fileExists(atPath: userDirectory.path))
    }

    /// Disabling mid-flush
    ///
    /// - Given: an enabled controller with several log files waiting to be sent
    /// - When:
    ///    - the controller is disabled while the first of them is being sent
    /// - Then:
    ///    - no other log file is sent, and the unsent ones stay on disk
    ///
    func testDisableMidFlushKeepsUnsentLogs() async throws {
        let namespace = "pending\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        let directory = logDirectory(forUser: nil, namespace: namespace)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let data = try LogEntryCodec().encode(entry: LogEntry(namespace: namespace, level: .error, message: "pending"))
        for index in 0 ..< 3 {
            FileManager.default.createFile(atPath: directory.appendingPathComponent("amplify.\(index).log").path, contents: data)
        }
        let controller = makeController(userIdentifier: nil, namespace: namespace)
        systemUnderTest = controller
        controller.enable()
        let sends = SendCounter()
        mockCloudWatchLogClient.putLogEventsHandler = { _ in
            await sends.increment()
            controller.disable()
            return PutLogEventsOutput()
        }

        try await controller.flushLogs()

        let sendCount = await sends.count
        XCTAssertEqual(sendCount, 1)
        let remaining = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { ((try? FileManager.default.attributesOfItem(atPath: $0.path)[.size] as? Int) ?? 0) > 0 }
        XCTAssertEqual(remaining.count, 2)
    }

    /// Logging while the current user changes
    ///
    /// - Given: an enabled controller
    /// - When:
    ///    - several tasks log and flush while the current user changes repeatedly
    /// - Then:
    ///    - every task completes
    ///    - a message logged afterwards lands in the last user's log directory. Run with Thread Sanitizer to
    ///      detect data races.
    ///
    func testLoggingWhileCurrentUserChanges() async throws {
        let controller = makeController(userIdentifier: nil)
        systemUnderTest = controller
        controller.enable()
        let users: [String?] = [nil, "user-a", "user-b", "user-c"]
        defer {
            for user in users.compactMap({ $0 }) {
                try? FileManager.default.removeItem(at: logDirectory(forUser: user).deletingLastPathComponent())
            }
        }

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for index in 0 ..< 100 {
                    controller.setCurrentUser(identifier: users[index % users.count])
                }
            }
            for _ in 0 ..< 4 {
                group.addTask {
                    for index in 0 ..< 250 {
                        controller.log(.error, "message \(index)", nil)
                    }
                }
            }
            group.addTask {
                for _ in 0 ..< 10 {
                    try? await controller.flushLogs()
                }
            }
        }

        let lastUser = "user-\(UUID().uuidString)"
        let directory = logDirectory(forUser: lastUser)
        defer { try? FileManager.default.removeItem(at: directory.deletingLastPathComponent()) }
        controller.setCurrentUser(identifier: lastUser)
        let message = UUID().uuidString
        controller.log(.error, message, nil)
        let logged = await waitUntil { (try? self.logContents(in: directory).contains(message)) == true }
        XCTAssertTrue(logged, "A message logged after the user changes should land in the last user's logs")
    }

    /// Session creation failure while registered as a sink
    ///
    /// - Given: a client registered as a logging sink, and a namespace whose log directory can't be created
    /// - When:
    ///    - a message is logged for that namespace
    /// - Then:
    ///    - the client reports the failure through its own sink without deadlocking on its lock
    ///
    func testSessionCreationFailureDoesNotDeadlockSink() async throws {
        // A user of its own keeps every directory this test causes under one path it removes.
        let userIdentifier = "user-\(UUID().uuidString)"
        let namespace = "blocked\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        let blocker = logDirectory(forUser: userIdentifier, namespace: namespace)
        defer { try? FileManager.default.removeItem(at: blocker.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: blocker.deletingLastPathComponent(), withIntermediateDirectories: true)
        // A file where the namespace's log directory should be makes session creation fail.
        XCTAssertTrue(FileManager.default.createFile(atPath: blocker.path, contents: Data()))

        let client = AmplifyCloudWatchClient(
            cloudWatchClient: mockCloudWatchLogClient,
            logGroupName: "logGroupName",
            networkMonitor: mockLoggingNetworkMonitor
        )
        client.setUserIdentifier(userIdentifier)
        AmplifyLogging.addSink(client)
        defer { AmplifyLogging.removeSink(client) }

        let emitted = expectation(description: "emit(message:) returns")
        // Its own thread, so a deadlock fails this test instead of blocking the runner. The generous timeout
        // only absorbs slow disks; a deadlocked emit never returns.
        Thread {
            client.emit(message: LogMessage(level: .error, name: namespace, content: "message"))
            emitted.fulfill()
        }.start()
        await fulfillment(of: [emitted], timeout: 30)

        let reportDirectory = logDirectory(forUser: userIdentifier, namespace: "CloudWatchLoggingSessionController")
        let reported = await waitUntil(timeout: 30) {
            (try? self.logContents(in: reportDirectory).contains("Error creating logging session")) == true
        }
        XCTAssertTrue(reported, "The session creation failure should be logged through the client's sink")
    }

    private func makeController(userIdentifier: String?, namespace: String? = nil) -> CloudWatchLoggingSessionController {
        CloudWatchLoggingSessionController(
            client: mockCloudWatchLogClient,
            logFilter: MockLoggingFilter(),
            namespace: namespace ?? self.namespace,
            logGroupName: "logGroupName",
            region: "us-east-1",
            localStoreMaxSizeInMB: 1,
            userIdentifier: userIdentifier,
            networkMonitor: mockLoggingNetworkMonitor,
            eventSubject: eventSubject
        )
    }

    /// Mirrors the directory `CloudWatchLoggingSession` derives for a user and namespace.
    private func logDirectory(forUser userIdentifier: String?, namespace: String? = nil) -> URL {
        let user = userIdentifier.map { identifier in
            SHA256.hash(data: Data(identifier.utf8)).map { String(format: "%02X", $0) }.joined()
        } ?? "guest"
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("amplify-cloudwatch-client")
                        .appendingPathComponent("logging")
                        .appendingPathComponent(user)
                        .appendingPathComponent((namespace ?? self.namespace).lowercased())
    }

    private func logContents(in directory: URL) throws -> String {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "log" }
            .map { try String(contentsOf: $0, encoding: .utf8) }
            .joined()
    }

    private func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        return condition()
    }

    private func staysTrue(for duration: TimeInterval, _ condition: () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(duration)
        while Date() < deadline {
            if !condition() { return false }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        return condition()
    }

    private func logFileCount(in directory: URL) throws -> Int {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .count(where: { $0.pathExtension == "log" })
    }

    private func uniqueNamespace(_ prefix: String) -> String {
        "\(prefix)\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
    }

    /// Runs `body` on its own utility `Thread` (a dispatch queue would starve) while every utility cooperative thread is held.
    private func whileCooperativePoolIsBusy(_ body: @escaping @Sendable () -> Void) async {
        let width = ProcessInfo.processInfo.activeProcessorCount
        let held = Locked(0)
        let released = Locked(false)
        let holders = (0 ..< width).map { _ in
            Task.detached(priority: .utility) {
                held.update { $0 += 1 }
                while !released.get() {
                    usleep(100)
                }
            }
        }
        await withCheckedContinuation { continuation in
            let thread = Thread {
                let deadline = Date().addingTimeInterval(2)
                while held.get() < width, Date() < deadline {
                    usleep(100)
                }
                body()
                released.update { $0 = true }
                continuation.resume()
            }
            thread.qualityOfService = .utility
            thread.start()
        }
        for holder in holders {
            await holder.value
        }
    }
}

extension CloudWatchLoggingSessionControllerTests {

    /// A user who comes back keeps the new session's logs
    ///
    /// - Given: a controller enabled for a signed-in user, with records still queued for that session
    /// - When:
    ///    - the user signs out and back in, then logs a message
    /// - Then:
    ///    - the message stays in the user's log directory, and none of the queued records end up there
    ///
    func testReturningUserKeepsNewSessionLogs() async throws {
        let namespace = uniqueNamespace("returning")
        let userIdentifier = "user-\(UUID().uuidString)"
        let userDirectory = logDirectory(forUser: userIdentifier, namespace: namespace)
        defer {
            try? FileManager.default.removeItem(at: userDirectory.deletingLastPathComponent())
            try? FileManager.default.removeItem(at: logDirectory(forUser: nil, namespace: namespace))
        }
        let controller = makeController(userIdentifier: userIdentifier, namespace: namespace)
        systemUnderTest = controller
        controller.enable()
        let message = UUID().uuidString
        // Holds off background work, so the outgoing session still has records queued when the user returns.
        await whileCooperativePoolIsBusy {
            for index in 0 ..< 200 {
                controller.error("queued \(index)", nil)
            }
            controller.setCurrentUser(identifier: nil)
            controller.setCurrentUser(identifier: userIdentifier)
            controller.error(message, nil)
        }

        let logged = await waitUntil { (try? self.logContents(in: userDirectory).contains(message)) == true }
        XCTAssertTrue(logged, "The returning user's message should be written")
        let kept = await staysTrue(for: 1) { (try? self.logContents(in: userDirectory).contains(message)) == true }
        XCTAssertTrue(kept, "Discarding the outgoing session's logs shouldn't remove the returning user's")
        XCTAssertFalse(try logContents(in: userDirectory).contains("queued"))
    }

    /// Changing the user mid-flush
    ///
    /// - Given: an enabled controller with several log files waiting to be sent
    /// - When:
    ///    - the current user changes while the first of them is being sent
    /// - Then:
    ///    - the flush stops without an error, and no other log file is sent
    ///
    func testUserChangeMidFlushStopsFlush() async throws {
        let namespace = uniqueNamespace("midflush")
        let directory = logDirectory(forUser: nil, namespace: namespace)
        let userIdentifier = "user-\(UUID().uuidString)"
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
            try? FileManager.default.removeItem(at: logDirectory(forUser: userIdentifier, namespace: namespace))
        }
        let data = try LogEntryCodec().encode(entry: LogEntry(namespace: namespace, level: .error, message: "pending"))
        for index in 0 ..< 3 {
            FileManager.default.createFile(atPath: directory.appendingPathComponent("amplify.\(index).log").path, contents: data)
        }
        let controller = makeController(userIdentifier: nil, namespace: namespace)
        systemUnderTest = controller
        controller.enable()
        let sends = SendCounter()
        mockCloudWatchLogClient.putLogEventsHandler = { _ in
            await sends.increment()
            controller.setCurrentUser(identifier: userIdentifier)
            return PutLogEventsOutput()
        }

        try await controller.flushLogs()

        let sendCount = await sends.count
        XCTAssertEqual(sendCount, 1)
    }

    /// Enabling an enabled controller
    ///
    /// - Given: an enabled controller
    /// - When:
    ///    - it's enabled again
    /// - Then:
    ///    - it keeps its session, so a single log file is open in its directory
    ///
    func testEnableWhileEnabledKeepsSession() throws {
        let namespace = uniqueNamespace("enabletwice")
        let directory = logDirectory(forUser: nil, namespace: namespace)
        defer { try? FileManager.default.removeItem(at: directory) }
        systemUnderTest = makeController(userIdentifier: nil, namespace: namespace)
        systemUnderTest.enable()
        systemUnderTest.enable()
        XCTAssertEqual(try logFileCount(in: directory), 1)
    }
}

// MARK: - Mocks

/// A value shared between the threads of a test.
private final class Locked<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func get() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func update(_ change: (inout Value) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        change(&value)
    }
}

private actor SendCounter {
    private(set) var count = 0

    func increment() {
        count += 1
    }
}

final class MockLoggingFilter: CloudWatchLoggingFilterBehavior {
    func canLog(withNamespace namespace: String?, logLevel: LogLevel, userIdentifier: String?) -> Bool {
        return true
    }

    func getDefaultLogLevel(forNamespace namespace: String?, userIdentifier: String?) -> LogLevel {
        return .verbose
    }
}

class MockLoggingNetworkMonitor: LoggingNetworkMonitor {
    var isOnline: Bool = true
    func startMonitoring(using queue: DispatchQueue) {}
    func stopMonitoring() {}
}
