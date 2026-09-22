//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCloudWatchLoggingPlugin
@testable import InternalCloudWatchLogging

import Amplify
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
        // Start from a clean, existing log directory. `LogRotation` selects its active file based
        // on the files already present, so log files left over from a previous test/run (only
        // `amplify.0.log` was deleted before) can cause the pre-written batch to be reused and
        // truncated, leaving no failing batch for `flushLogs` to consume and making the test flaky.
        // The directory must exist because the test writes `amplify.0.log` with
        // `FileManager.createFile`, which does not create intermediate directories.
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

    private func getLogFile() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("amplify")
                                 .appendingPathComponent("logging")
                                 .appendingPathComponent("guest")
                                 .appendingPathComponent(category)
                                 .appendingPathComponent("amplify.0.log")
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
