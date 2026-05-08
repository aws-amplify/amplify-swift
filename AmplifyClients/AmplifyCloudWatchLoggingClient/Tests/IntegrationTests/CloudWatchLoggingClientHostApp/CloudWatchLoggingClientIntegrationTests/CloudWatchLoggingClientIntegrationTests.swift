//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AmplifyFoundationBridge
import AWSCloudWatchLogs
import AWSPluginsCore
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@_spi(AmplifyExperimental) @testable import AmplifyCloudWatchLoggingClient
internal import InternalAmplifyCredentials
internal import ClientRuntime

class CloudWatchLoggingClientIntegrationTests: XCTestCase {

    static let amplifyOutputsFile =
        "testconfiguration/CloudWatchLoggingClientIntegrationTests-amplify_outputs"
    static let configurationFile =
        "testconfiguration/CloudWatchLoggingClientIntegrationTests-configuration"

    static var credentialsProvider: (any AmplifyFoundation.AWSCredentialsProvider)!
    static var cloudWatchConfig: CloudWatchClientConfiguration!
    private static var isConfigured = false

    var loggingClient: AmplifyCloudWatchLoggingClient!

    override func setUp() async throws {
        continueAfterFailure = false

        if !Self.isConfigured {
            // Configure Amplify with Auth for credentials
            if !Amplify.isConfigured {
                try Amplify.add(plugin: AWSCognitoAuthPlugin())
                let data = try TestConfigHelper.retrieve(forResource: Self.amplifyOutputsFile)
                try Amplify.configure(with: .data(data))
            }

            Self.credentialsProvider = SDKToFoundationCredentialsAdapter(
                resolver: AWSAuthService().getCredentialIdentityResolver()
            )

            // Load CloudWatch client configuration
            Self.cloudWatchConfig = try TestConfigHelper.retrieveCloudWatchClientConfiguration(
                forResource: Self.configurationFile
            )

            Self.isConfigured = true
        }

        let config = Self.cloudWatchConfig.cloudWatchClient
        let logLevel = LogLevel.from(string: config.loggingConstraints.defaultLogLevel)

        loggingClient = try AmplifyCloudWatchLoggingClient(
            region: config.region,
            credentialsProvider: Self.credentialsProvider,
            options: .init(
                logGroupName: config.logGroupName,
                localStoreMaxSizeInMB: config.localStoreMaxSizeInMB,
                flushStrategy: .interval(TimeInterval(config.flushIntervalInSeconds)),
                loggingConstraints: LoggingConstraints(defaultLogLevel: logLevel)
            )
        )

        try await Task.sleep(seconds: 5)
    }

    override func tearDown() async throws {
        loggingClient = nil
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? NSTemporaryDirectory()
        let directory = documents.appendingPathComponent("amplify-cloudwatch-client").appendingPathComponent("logging")
        let url = URL(fileURLWithPath: directory)
        guard FileManager.default.fileExists(atPath: directory) else { return }
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )
        for fileURL in fileURLs {
            try FileManager.default.removeItem(at: fileURL)
        }
        try FileManager.default.removeItem(atPath: directory)
    }

    /// - Given: an AmplifyCloudWatchLoggingClient
    /// - When: the escape hatch is requested
    /// - Then: the AWS CloudWatch client is returned
    func testGetEscapeHatch() throws {
        let cloudWatchClient = try loggingClient.getCloudWatchLogsClient()
        XCTAssertNotNil(cloudWatchClient)
    }

    /// - Given: an AmplifyCloudWatchLoggingClient
    /// - When: log messages are emitted and flushed
    /// - Then: the log messages are sent to AWS CloudWatch
    func testFlushLogWithMessages() async throws {
        let namespace = UUID().uuidString
        let message = "this is an error message in the integration test \(Date().epochMilliseconds)"

        loggingClient.emit(message: LogMessage(level: .error, name: namespace, content: message, error: nil))
        loggingClient.emit(message: LogMessage(level: .debug, name: namespace, content: message, error: nil))
        loggingClient.emit(message: LogMessage(level: .warn, name: namespace, content: message, error: nil))
        loggingClient.emit(message: LogMessage(level: .info, name: namespace, content: message, error: nil))

        try await loggingClient.flushLogs()
        try await Task.sleep(seconds: 30)

        let cloudWatchClient = try loggingClient.getCloudWatchLogsClient()
        try await verifyMessagesSent(
            client: cloudWatchClient,
            logGroupName: Self.cloudWatchConfig.cloudWatchClient.logGroupName,
            messageCount: 4,
            message: message,
            namespace: namespace
        )
    }

    /// - Given: an AmplifyCloudWatchLoggingClient with logging enabled
    /// - When: a verbose log message is emitted and flushed
    /// - Then: the verbose log message is sent to AWS CloudWatch
    func testFlushLogWithVerboseMessageAfterEnabling() async throws {
        let namespace = UUID().uuidString
        let message = "this is a verbose message after enabling \(Date().epochMilliseconds)"

        loggingClient.enable()
        let logMessage = LogMessage(level: .verbose, name: namespace, content: message, error: nil)
        loggingClient.emit(message: logMessage)

        try await Task.sleep(seconds: 1)
        try await loggingClient.flushLogs()
        try await Task.sleep(seconds: 30)

        let cloudWatchClient = try loggingClient.getCloudWatchLogsClient()
        try await verifyMessageSent(
            client: cloudWatchClient,
            logGroupName: Self.cloudWatchConfig.cloudWatchClient.logGroupName,
            logLevel: "verbose",
            message: message,
            namespace: namespace
        )
    }

    /// - Given: an AmplifyCloudWatchLoggingClient with logging disabled
    /// - When: a verbose log message is emitted and flushed
    /// - Then: the verbose log message is NOT sent to AWS CloudWatch
    func testFlushLogWithVerboseMessageAfterDisabling() async throws {
        let namespace = UUID().uuidString
        let message = "this is a verbose message after disabling \(Date().epochMilliseconds)"

        loggingClient.disable()
        let logMessage = LogMessage(level: .verbose, name: namespace, content: message, error: nil)
        loggingClient.emit(message: logMessage)

        try await Task.sleep(seconds: 1)
        try await loggingClient.flushLogs()
        try await Task.sleep(seconds: 30)

        let cloudWatchClient = try loggingClient.getCloudWatchLogsClient()
        try await verifyMessageNotSent(
            client: cloudWatchClient,
            logGroupName: Self.cloudWatchConfig.cloudWatchClient.logGroupName,
            message: message
        )
    }

    /// - Given: two AmplifyCloudWatchLoggingClient instances targeting the same log group
    /// - When: each client emits and flushes a unique message
    /// - Then: the messages are written to different log streams (isolated by storagePathIdentifier)
    func testTwoClientsWithSameLogGroupUseDifferentStreams() async throws {
        let config = Self.cloudWatchConfig.cloudWatchClient
        let logLevel = LogLevel.from(string: config.loggingConstraints.defaultLogLevel)

        let client1 = try AmplifyCloudWatchLoggingClient(
            region: config.region,
            credentialsProvider: Self.credentialsProvider,
            options: .init(
                logGroupName: config.logGroupName,
                localStoreMaxSizeInMB: config.localStoreMaxSizeInMB,
                flushStrategy: .interval(TimeInterval(config.flushIntervalInSeconds)),
                loggingConstraints: LoggingConstraints(defaultLogLevel: logLevel)
            )
        )

        let client2 = try AmplifyCloudWatchLoggingClient(
            region: config.region,
            credentialsProvider: Self.credentialsProvider,
            options: .init(
                logGroupName: config.logGroupName,
                localStoreMaxSizeInMB: config.localStoreMaxSizeInMB,
                flushStrategy: .interval(TimeInterval(config.flushIntervalInSeconds)),
                loggingConstraints: LoggingConstraints(defaultLogLevel: logLevel)
            )
        )

        // Verify different client IDs
        XCTAssertNotEqual(client1.id, client2.id)

        let namespace = UUID().uuidString
        let message1 = "client1 message \(Date().epochMilliseconds)"
        let message2 = "client2 message \(Date().epochMilliseconds)"

        client1.emit(message: LogMessage(level: .error, name: namespace, content: message1, error: nil))
        client2.emit(message: LogMessage(level: .error, name: namespace, content: message2, error: nil))

        try await Task.sleep(seconds: 1)
        try await client1.flushLogs()
        try await client2.flushLogs()
        try await Task.sleep(seconds: 30)

        // Verify both messages arrived in CloudWatch
        let cloudWatchClient = try client1.getCloudWatchLogsClient()

        try await verifyMessageSent(
            client: cloudWatchClient,
            logGroupName: config.logGroupName,
            logLevel: "error",
            message: message1,
            namespace: namespace
        )

        try await verifyMessageSent(
            client: cloudWatchClient,
            logGroupName: config.logGroupName,
            logLevel: "error",
            message: message2,
            namespace: namespace
        )

        // Verify they used different streams by checking stream names contain different client IDs
        let endTime = Date()
        let startTime = endTime.addingTimeInterval(-120)
        let response = try await cloudWatchClient.describeLogStreams(input: DescribeLogStreamsInput(
            descending: true,
            logGroupName: config.logGroupName,
            orderBy: .lasteventtime
        ))

        let streams = response.logStreams ?? []
        let client1Streams = streams.filter { $0.logStreamName?.contains(client1.id) == true }
        let client2Streams = streams.filter { $0.logStreamName?.contains(client2.id) == true }

        XCTAssertFalse(client1Streams.isEmpty, "Client 1 should have its own log stream")
        XCTAssertFalse(client2Streams.isEmpty, "Client 2 should have its own log stream")
        XCTAssertNotEqual(
            client1Streams.first?.logStreamName,
            client2Streams.first?.logStreamName,
            "Clients should use different stream names"
        )

        await client1.reset()
        await client2.reset()
    }

    // MARK: - Helpers

    func verifyMessagesSent(
        client: CloudWatchLogsClient,
        logGroupName: String?,
        messageCount: Int,
        message: String,
        namespace: String
    ) async throws {

        let events = try await getLastMessageSent(
            client: client,
            logGroupName: logGroupName,
            expectedMessageCount: messageCount,
            message: message,
            requestAttempt: 0
        )
        XCTAssertEqual(events?.count, messageCount)
        guard let sentLogMessage = events?.first?.message else {
            XCTFail("Unable to verify last log message")
            return
        }
        XCTAssertTrue(sentLogMessage.contains(message))
        XCTAssertTrue(sentLogMessage.contains(namespace))
    }

    func verifyMessageSent(
        client: CloudWatchLogsClient,
        logGroupName: String?,
        logLevel: String,
        message: String,
        namespace: String
    ) async throws {

        let events = try await getLastMessageSent(
            client: client,
            logGroupName: logGroupName,
            expectedMessageCount: 1,
            message: message,
            requestAttempt: 0
        )
        XCTAssertEqual(events?.count, 1)
        guard let sentLogMessage = events?.first?.message else {
            XCTFail("Unable to verify last log message")
            return
        }
        XCTAssertTrue(sentLogMessage.lowercased().contains(logLevel))
        XCTAssertTrue(sentLogMessage.contains(message))
        XCTAssertTrue(sentLogMessage.contains(namespace))
    }

    func verifyMessageNotSent(
        client: CloudWatchLogsClient,
        logGroupName: String?,
        message: String
    ) async throws {

        let events = try await getLastMessageSent(
            client: client,
            logGroupName: logGroupName,
            expectedMessageCount: 1,
            message: message,
            requestAttempt: 0
        )
        XCTAssertEqual(events?.count, 0)
    }

    func getLastMessageSent(
        client: CloudWatchLogsClient,
        logGroupName: String?,
        expectedMessageCount: Int,
        message: String,
        requestAttempt: Int
    ) async throws -> [CloudWatchLogsClientTypes.FilteredLogEvent]? {
        let endTime = Date()
        let durationInMinutes = requestAttempt + 1
        let startTime = endTime.addingTimeInterval(TimeInterval(-durationInMinutes * 60))
        var events = try await AWSCloudWatchClientHelper.getFilterLogEventCount(
            client: client,
            filterPattern: message,
            startTime: startTime,
            endTime: endTime,
            logGroupName: logGroupName
        )

        if events?.count != expectedMessageCount && requestAttempt <= 5 {
            try await loggingClient.flushLogs()
            try await Task.sleep(seconds: 30)
            let attempted = requestAttempt + 1
            events = try await getLastMessageSent(
                client: client,
                logGroupName: logGroupName,
                expectedMessageCount: expectedMessageCount,
                message: message,
                requestAttempt: attempted
            )
        }

        return events
    }
}

// MARK: - Helpers

private extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let nanoseconds = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}

extension AmplifyFoundation.LogLevel {
    static func from(string: String) -> AmplifyFoundation.LogLevel {
        switch string.lowercased() {
        case "error": return .error
        case "warn": return .warn
        case "info": return .info
        case "debug": return .debug
        case "verbose": return .verbose
        case "none": return .none
        default: return .error
        }
    }
}
