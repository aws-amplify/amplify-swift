//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AWSCloudWatchLogs
import Combine
import XCTest

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
}

// MARK: - Mocks

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
