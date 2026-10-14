//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCloudWatchLoggingPlugin
@testable import InternalCloudWatchLogging

import Amplify
import AWSCloudWatchLogs
import CryptoKit
import Network
import XCTest
@testable import AmplifyTestCommon

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
final class AWSCloudWatchLoggingSessionControllerTests: XCTestCase, @unchecked Sendable {
    var systemUnderTest: AWSCloudWatchLoggingSessionController!
    let mockCredentialProvider = MockCredentialsProvider()
    let mockAuth = MockAuthCategoryPlugin()
    let mockLoggingFilter = MockLoggingFilter()
    let mockCloudWatchLogClient = MockCloudWatchLogsClient()
    let mockLoggingNetworkMonitor = MockLoggingNetworkMonitor()
    let category = "amplifytest"
    var unsubscribeToken: UnsubscribeToken?

    override func setUp() async throws {
        // Remove prior log files, then recreate the directory required by `FileManager.createFile`.
        resetLogDirectory()
    }

    override func tearDown() async throws {
        systemUnderTest = nil
        if let token = unsubscribeToken {
            Amplify.Hub.removeListener(token)
        }
        // Remove the whole logging directory, not just `amplify.0.log`; the session under test
        // rotates to additional files (e.g. `amplify.1.log`) that would otherwise leak between tests.
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let loggingDirectory = documents.appendingPathComponent("amplify").appendingPathComponent("logging")
        try? FileManager.default.removeItem(at: loggingDirectory)
    }

    /// Removes any leftover log files and recreates the empty category directory the test writes into.
    private func resetLogDirectory() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let loggingDirectory = documents.appendingPathComponent("amplify").appendingPathComponent("logging")
        try? FileManager.default.removeItem(at: loggingDirectory)
        let categoryDirectory = getLogFile().deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: categoryDirectory, withIntermediateDirectories: true)
    }

    /// Given: an AWSCloudWatchLoggingSessionController
    /// When: a flush log is called and fails to flush logs
    /// Then: a flushLogFailure Hub Event is sent to the Logging channel
    func testConsumeFailureSendsHubEvent() async throws {
        let hubEventExpectation = expectation(description: "Should receive the hub event")
        let token = Amplify.Hub.listen(to: .logging) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Logging.flushLogFailure:
                hubEventExpectation.fulfill()
            default:
                break
            }
        }
        unsubscribeToken = token

        // `Hub.listen` attaches the listener asynchronously. Wait for it to be
        // registered before triggering the flush, otherwise the synchronously
        // dispatched `flushLogFailure` event can be emitted before the listener
        // exists and the expectation never fulfills.
        guard try await HubListenerTestUtilities.waitForListener(with: token, timeout: 5) else {
            XCTFail("Hub listener was not registered")
            return
        }

        let bytes = (0 ..< 1_024).map { _ in UInt8.random(in: 0 ..< 255) }
        let fileURL = getLogFile()
        FileManager.default.createFile(
            atPath: fileURL.path,
            contents: Data(bytes),
            attributes: [FileAttributeKey: Any]()
        )
        systemUnderTest = AWSCloudWatchLoggingSessionController(
            credentialIdentityResolver: mockCredentialProvider,
            authentication: mockAuth,
            logFilter: mockLoggingFilter,
            category: category,
            namespace: nil,
            logLevel: .error,
            logGroupName: "logGroupName",
            region: "us-east-1",
            localStoreMaxSizeInMB: 1,
            userIdentifier: nil,
            networkMonitor: mockLoggingNetworkMonitor
        )
        systemUnderTest.client = mockCloudWatchLogClient
        systemUnderTest.enable()
        try await systemUnderTest.flushLogs()
        await fulfillment(of: [hubEventExpectation], timeout: 10)
    }

    /// Changing the user resets the outgoing session's logs only
    ///
    /// - Given: a controller enabled for a guest whose log directory has entries, and entries left on disk
    ///   by a previous launch for the user about to sign in
    /// - When:
    ///    - the current user changes to that user
    /// - Then:
    ///    - the guest's entries are deleted
    ///    - the incoming user's entries are kept
    ///
    func testUserChangeResetsOnlyOutgoingSessionLogs() async throws {
        let userIdentifier = "user-\(UUID().uuidString)"
        let guestDirectory = getLogFile().deletingLastPathComponent()
        let userDirectory = logDirectory(forUser: userIdentifier)
        try FileManager.default.createDirectory(at: userDirectory, withIntermediateDirectories: true)
        let pending = Data(repeating: 0x61, count: 512)
        FileManager.default.createFile(atPath: getLogFile().path, contents: pending)
        FileManager.default.createFile(atPath: userDirectory.appendingPathComponent("amplify.0.log").path, contents: pending)

        let controller = makeController(userIdentifier: nil)
        systemUnderTest = controller
        controller.enable()
        // Holds off background work, so the guest's logs must be gone without it.
        await whileCooperativePoolIsBusy {
            controller.setCurrentUser(identifier: userIdentifier)
        }

        let guestReset = await waitUntil { (try? self.totalLogBytes(in: guestDirectory)) == 0 }
        XCTAssertTrue(guestReset, "The outgoing guest session's logs should be reset")
        XCTAssertEqual(try totalLogBytes(in: userDirectory), pending.count)
    }

    /// Changing the user while disabled
    ///
    /// - Given: a controller that was enabled and then disabled
    /// - When:
    ///    - the current user changes
    /// - Then:
    ///    - no session is created for the new user until the controller is enabled again
    ///
    func testUserChangeWhileDisabledDoesNotCreateSession() {
        let userIdentifier = "user-\(UUID().uuidString)"
        let userDirectory = logDirectory(forUser: userIdentifier)
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
        let directory = getLogFile().deletingLastPathComponent()
        let data = try LogEntryCodec().encode(entry: LogEntry(category: category, namespace: nil, level: .error, message: "pending"))
        for index in 0 ..< 3 {
            FileManager.default.createFile(atPath: directory.appendingPathComponent("amplify.\(index).log").path, contents: data)
        }
        let controller = makeController(userIdentifier: nil)
        systemUnderTest = controller
        controller.enable()
        let sends = AtomicValue(initialValue: 0)
        mockCloudWatchLogClient.putLogEventsHandler = { _ in
            _ = sends.increment()
            controller.disable()
            return PutLogEventsOutput()
        }

        try await controller.flushLogs()

        XCTAssertEqual(sends.get(), 1)
        XCTAssertEqual(try totalLogBytes(in: directory), 2 * data.count)
    }

    /// Logging while the current user changes
    ///
    /// - Given: an enabled controller
    /// - When:
    ///    - several tasks log, flush and set the log level while the current user changes repeatedly
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

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for index in 0 ..< 100 {
                    controller.setCurrentUser(identifier: users[index % users.count])
                }
            }
            for _ in 0 ..< 4 {
                group.addTask {
                    for index in 0 ..< 250 {
                        controller.error("message \(index)")
                    }
                }
            }
            group.addTask {
                for index in 0 ..< 100 {
                    controller.logLevel = index.isMultiple(of: 2) ? .error : .verbose
                }
            }
            group.addTask {
                for _ in 0 ..< 10 {
                    try? await controller.flushLogs()
                }
            }
        }

        let lastUser = "user-\(UUID().uuidString)"
        controller.setCurrentUser(identifier: lastUser)
        let message = UUID().uuidString
        controller.error(message)
        let directory = logDirectory(forUser: lastUser)
        let logged = await waitUntil { (try? self.logContents(in: directory).contains(message)) == true }
        XCTAssertTrue(logged, "A message logged after the user changes should land in the last user's logs")
    }

    private func makeController(userIdentifier: String?) -> AWSCloudWatchLoggingSessionController {
        let controller = AWSCloudWatchLoggingSessionController(
            credentialIdentityResolver: mockCredentialProvider,
            authentication: mockAuth,
            logFilter: mockLoggingFilter,
            category: category,
            namespace: nil,
            logLevel: .error,
            logGroupName: "logGroupName",
            region: "us-east-1",
            localStoreMaxSizeInMB: 1,
            userIdentifier: userIdentifier,
            networkMonitor: mockLoggingNetworkMonitor
        )
        controller.client = mockCloudWatchLogClient
        return controller
    }

    private func getLogFile() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("amplify")
                                 .appendingPathComponent("logging")
                                 .appendingPathComponent("guest")
                                 .appendingPathComponent(category)
                                 .appendingPathComponent("amplify.0.log")
    }

    /// Mirrors the directory `AWSCloudWatchLoggingSession` derives for a signed-in user.
    private func logDirectory(forUser userIdentifier: String) -> URL {
        let digest = SHA256.hash(data: Data(userIdentifier.utf8))
        let normalized = digest.map { String(format: "%02X", $0) }.joined()
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("amplify")
                        .appendingPathComponent("logging")
                        .appendingPathComponent(normalized)
                        .appendingPathComponent(category)
    }

    /// The directory's log files; none once it has been discarded.
    private func logFiles(in directory: URL) throws -> [URL] {
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "log" }
    }

    private func totalLogBytes(in directory: URL) throws -> Int {
        try logFiles(in: directory).reduce(0) { total, file in
            let size = try FileManager.default.attributesOfItem(atPath: file.path)[.size] as? Int ?? 0
            return total + size
        }
    }

    private func logContents(in directory: URL) throws -> String {
        try logFiles(in: directory).map { try String(contentsOf: $0, encoding: .utf8) }.joined()
    }
}

extension AWSCloudWatchLoggingSessionControllerTests {

    /// A user who comes back keeps the new session's logs
    ///
    /// - Given: a controller enabled for a signed-in user, with records still queued for that session
    /// - When:
    ///    - the user signs out and back in, then logs a message
    /// - Then:
    ///    - the message stays in the user's log directory, and none of the queued records end up there
    ///
    func testReturningUserKeepsNewSessionLogs() async throws {
        let userIdentifier = "user-\(UUID().uuidString)"
        let userDirectory = logDirectory(forUser: userIdentifier)
        let controller = makeController(userIdentifier: userIdentifier)
        systemUnderTest = controller
        controller.enable()
        let message = UUID().uuidString
        // Holds off background work, so the outgoing session still has records queued when the user returns.
        await whileCooperativePoolIsBusy {
            for index in 0 ..< 200 {
                controller.error("queued \(index)")
            }
            controller.setCurrentUser(identifier: nil)
            controller.setCurrentUser(identifier: userIdentifier)
            controller.error(message)
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
        let directory = getLogFile().deletingLastPathComponent()
        let data = try LogEntryCodec().encode(entry: LogEntry(category: category, namespace: nil, level: .error, message: "pending"))
        for index in 0 ..< 3 {
            FileManager.default.createFile(atPath: directory.appendingPathComponent("amplify.\(index).log").path, contents: data)
        }
        let controller = makeController(userIdentifier: nil)
        systemUnderTest = controller
        controller.enable()
        let sends = AtomicValue(initialValue: 0)
        let userIdentifier = "user-\(UUID().uuidString)"
        mockCloudWatchLogClient.putLogEventsHandler = { _ in
            _ = sends.increment()
            controller.setCurrentUser(identifier: userIdentifier)
            return PutLogEventsOutput()
        }

        try await controller.flushLogs()

        XCTAssertEqual(sends.get(), 1)
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
        let directory = getLogFile().deletingLastPathComponent()
        systemUnderTest = makeController(userIdentifier: nil)
        systemUnderTest.enable()
        systemUnderTest.enable()
        XCTAssertEqual(try logFiles(in: directory).count, 1)
    }
}

class MockLoggingFilter: AWSCloudWatchLoggingFilterBehavior {
    func canLog(withCategory category: String, logLevel: LogLevel, userIdentifier: String?) -> Bool {
        return true
    }

    func getDefaultLogLevel(forCategory category: String, userIdentifier: String?) -> LogLevel {
        return .verbose
    }
}

class MockLoggingNetworkMonitor: LoggingNetworkMonitor {
    var isOnline: Bool = true
    func startMonitoring(using queue: DispatchQueue) {}
    func stopMonitoring() {}
}
