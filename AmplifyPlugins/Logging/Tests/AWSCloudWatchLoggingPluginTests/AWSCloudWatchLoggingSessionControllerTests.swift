//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCloudWatchLoggingPlugin

import XCTest
import Amplify
import Network
@testable import AmplifyTestCommon

final class AWSCloudWatchLoggingSessionControllerTests: XCTestCase {
    var systemUnderTest: AWSCloudWatchLoggingSessionController!
    let mockCredentialProvider = MockCredentialsProvider()
    let mockAuth = MockAuthCategoryPlugin()
    let mockLoggingFilter = MockLoggingFilter()
    let mockCloudWatchLogClient = MockCloudWatchLogsClient()
    let mockLoggingNetworkMonitor = MockLoggingNetworkMonitor()
    let category = "amplifytest"
    var unsubscribeToken: UnsubscribeToken?

    override func tearDown() async throws {
        systemUnderTest = nil
        if let token = unsubscribeToken {
            Amplify.Hub.removeListener(token)
        }
        let file = getLogFile()
        do {
            try FileManager.default.removeItem(atPath: file.path)
        } catch {

        }
    }

    /// Given: an AWSCloudWatchLoggingSessionController
    /// When: a flush log is called and fails to flush logs
    /// Then: a flushLogFailure Hub Event is sent to the Logging channel
    func testConsumeFailureSendsHubEvent() async throws {
        let hubEventExpectation = expectation(description: "Should receive the hub event")
        unsubscribeToken = Amplify.Hub.listen(to: .logging) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Logging.flushLogFailure:
                hubEventExpectation.fulfill()
            default:
                break
            }
        }

        let bytes = (0..<1024).map { _ in UInt8.random(in: 0..<255) }
        let fileURL = getLogFile()
        FileManager.default.createFile(atPath: fileURL.path,
                                       contents: Data(bytes),
                                       attributes: [FileAttributeKey: Any]())
        systemUnderTest = AWSCloudWatchLoggingSessionController(
            credentialsProvider: mockCredentialProvider,
            authentication: mockAuth,
            logFilter: mockLoggingFilter,
            category: category,
            namespace: nil,
            logLevel: .error,
            logGroupName: "logGroupName",
            region: "us-east-1",
            localStoreMaxSizeInMB: 1,
            userIdentifier: nil,
            networkMonitor: mockLoggingNetworkMonitor)
        systemUnderTest.client = mockCloudWatchLogClient
        systemUnderTest.enable()
        try await systemUnderTest.flushLogs()
        await fulfillment(of: [hubEventExpectation], timeout: 2)
    }
    
    /// Given: an AWSCloudWatchLoggingSessionController
    /// When: the user identifier is changed
    /// Then: a flush log is called and fails with a flushLogFailure hub event
    func testResetLogsWhenIdentifierChanges() async throws {
        let hubEventExpectation = expectation(description: "should receive flush failure event")
        unsubscribeToken = Amplify.Hub.listen(to: .logging) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Logging.flushLogFailure:
                hubEventExpectation.fulfill()
            default:
                break
            }
        }

        let bytes = (0..<1024).map { _ in UInt8.random(in: 0..<255) }
        let fileURL = getLogFile()
        FileManager.default.createFile(atPath: fileURL.path,
                                       contents: Data(bytes),
                                       attributes: [FileAttributeKey: Any]())
        systemUnderTest = AWSCloudWatchLoggingSessionController(
            credentialsProvider: mockCredentialProvider,
            authentication: mockAuth,
            logFilter: mockLoggingFilter,
            category: category,
            namespace: nil,
            logLevel: .error,
            logGroupName: "logGroupName",
            region: "us-east-1",
            localStoreMaxSizeInMB: 1,
            userIdentifier: nil,
            networkMonitor: mockLoggingNetworkMonitor)
        systemUnderTest.client = mockCloudWatchLogClient
        systemUnderTest.enable()
        systemUnderTest.setCurrentUser(identifier: "123")
        await fulfillment(of: [hubEventExpectation], timeout: 5)
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
