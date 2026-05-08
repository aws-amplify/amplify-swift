//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AWSCloudWatchLogs
import Combine
import Smithy
import SmithyIdentity
import XCTest

@_spi(AmplifyExperimental) @testable import AmplifyCloudWatchLoggingClient
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
    /// Note: This test may be flaky in CI due to async timing (same as plugin equivalent).
    func testConsumeFailureSendsEvent() async throws {
        let eventExpectation = expectation(description: "Should receive the flush failure event")
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
            credentialIdentityResolver: MockCredentialIdentityResolver(),
            logFilter: MockLoggingFilter(),
            namespace: namespace,
            logLevel: .error,
            logGroupName: "logGroupName",
            region: "us-east-1",
            localStoreMaxSizeInMB: 1,
            userIdentifier: nil,
            networkMonitor: mockLoggingNetworkMonitor,
            eventSubject: eventSubject
        )
        systemUnderTest.client = mockCloudWatchLogClient
        systemUnderTest.enable()

        // Log an entry through the controller so there's data to flush
        systemUnderTest.log(.error, "test error message", nil)
        try await Task.sleep(seconds: 0.5)

        try await systemUnderTest.flushLogs()
        await fulfillment(of: [eventExpectation], timeout: 10)
    }
}

// MARK: - Mocks

class MockLoggingFilter: CloudWatchLoggingFilterBehavior {
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

class MockCredentialIdentityResolver: AWSCredentialIdentityResolver {
    func getIdentity(identityProperties: Smithy.Attributes?) async throws -> AWSCredentialIdentity {
        return .init(accessKey: "test", secret: "test")
    }
}
