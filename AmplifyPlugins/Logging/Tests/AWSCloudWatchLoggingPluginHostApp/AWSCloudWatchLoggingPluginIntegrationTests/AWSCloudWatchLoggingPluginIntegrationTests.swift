//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSCloudWatchLogs
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSCloudWatchLoggingPlugin

class AWSCloudWatchLoggingPluginIntergrationTests: XCTestCase {
    let amplifyConfigurationFile = "testconfiguration/AWSCloudWatchLoggingPluginIntegrationTests-amplifyconfiguration"
    let amplifyOutputsFile = "testconfiguration/AWSCloudWatchLoggingPluginIntegrationTests-amplify_outputs"
    #if os(tvOS)
    var amplifyConfigurationLoggingFile = "testconfiguration/AWSCloudWatchLoggingPluginIntegrationTests-amplifyconfiguration_logging_tvOS"
    #elseif os(watchOS)
    var amplifyConfigurationLoggingFile = "testconfiguration/AWSCloudWatchLoggingPluginIntegrationTests-amplifyconfiguration_logging_watchOS"
    #else
    var amplifyConfigurationLoggingFile = "testconfiguration/AWSCloudWatchLoggingPluginIntegrationTests-amplifyconfiguration_logging"
    #endif
    var loggingConfiguration: AWSCloudWatchLoggingPluginConfiguration?
    
    var useGen2Configuration: Bool {
        ProcessInfo.processInfo.arguments.contains("GEN2")
    }

    override func setUp() async throws {
        continueAfterFailure = false
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())

            if useGen2Configuration {
                amplifyConfigurationLoggingFile += "_gen2"
            }

            let loggingConfigurationFile = try TestConfigHelper.retrieveLoggingConfiguration(forResource: amplifyConfigurationLoggingFile)
            loggingConfiguration = try AWSCloudWatchLoggingPluginConfiguration.loadConfiguration(from: loggingConfigurationFile)
            let loggingPlugin = AWSCloudWatchLoggingPlugin(loggingPluginConfiguration: loggingConfiguration)
            try Amplify.add(plugin: loggingPlugin)

            if useGen2Configuration {
                let data = try TestConfigHelper.retrieve(forResource: amplifyOutputsFile)
                try Amplify.configure(with: .data(data))
            } else {
                let configuration = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: amplifyConfigurationFile)
                try Amplify.configure(configuration)
            }

            try await Task.sleep(seconds: 5)
        } catch {
            XCTFail("Failed to initialize and configure Amplify: \(error)")
        }
        XCTAssertNotNil(Amplify.Auth.plugin)
        XCTAssertTrue(Amplify.Auth.isConfigured)
    }

    override func tearDown() async throws {
        await Amplify.reset()
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? NSTemporaryDirectory()
        let directory = documents.appendingPathComponent("amplify").appendingPathComponent("logging")
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: URL(string: directory)!,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles)
        for fileURL in fileURLs {
            try FileManager.default.removeItem(at: fileURL)
        }
        try FileManager.default.removeItem(atPath: directory)
    }
    
    /// - Given: a AWS CloudWatch Logging plugin
    /// - When: the escape hatch is requested
    /// - Then: the AWS CloudWatch client is returned
    func testGetEscapeHatch() throws {
        let plugin = try Amplify.Logging.getPlugin(for: "awsCloudWatchLoggingPlugin")
        guard let loggingPlugin = plugin as? AWSCloudWatchLoggingPlugin else {
            XCTFail("Could not get plugin of type AWSCloudWatchLoggingPlugin")
            return
        }
        let cloudWatchClient = loggingPlugin.getEscapeHatch()
        XCTAssertNotNil(cloudWatchClient)
    }
    
    /// - Given: a AWS CloudWatch Logging plugin
    /// - When: log messages is logged and flushed
    /// - Then: the log messages are logged and sent to AWS CloudWatch
    func testFlushLogWithMessages() async throws {
        let category = "Analytics"
        let namespace = UUID().uuidString
        let message = "this is an error message in the integration test \(Date().epochMilliseconds)"
        let logger = Amplify.Logging.logger(forCategory: category, forNamespace: namespace)
        logger.error(message)
        logger.debug(message)
        logger.warn(message)
        logger.info(message)
        let plugin = try Amplify.Logging.getPlugin(for: "awsCloudWatchLoggingPlugin")
        guard let loggingPlugin = plugin as? AWSCloudWatchLoggingPlugin else {
            XCTFail("Could not get plugin of type AWSCloudWatchLoggingPlugin")
            return
        }
        try await loggingPlugin.flushLogs()
        try await Task.sleep(seconds: 30)
        let cloudWatchClient = loggingPlugin.getEscapeHatch()
        try await verifyMessagesSent(plugin: loggingPlugin,
                                     client: cloudWatchClient,
                                     logGroupName: loggingConfiguration?.logGroupName,
                                     messageCount: 4,
                                     message: message,
                                     category: category,
                                     namespace: namespace)
    }

    
    /// - Given: a AWS CloudWatch Logging plugin with logging enabled
    /// - When: an error log message is logged and flushed
    /// - Then: the eror log message is logged and sent to AWS CloudWatch
    func testFlushLogWithVerboseMessageAfterEnablingPlugin() async throws {
        let category = "Storage"
        let namespace = UUID().uuidString
        let message = "this is an verbose message in the integration test after enabling logging \(Date().epochMilliseconds)"
        let logger = Amplify.Logging.logger(forCategory: category, forNamespace: namespace)
        Amplify.Logging.enable()
        logger.verbose(message)
        let plugin = try Amplify.Logging.getPlugin(for: "awsCloudWatchLoggingPlugin")
        guard let loggingPlugin = plugin as? AWSCloudWatchLoggingPlugin else {
            XCTFail("Could not get plugin of type AWSCloudWatchLoggingPlugin")
            return
        }
        try await loggingPlugin.flushLogs()
        try await Task.sleep(seconds: 30)
        let cloudWatchClient = loggingPlugin.getEscapeHatch()
        try await verifyMessageSent(plugin: loggingPlugin,
                                    client: cloudWatchClient,
                                    logGroupName: loggingConfiguration?.logGroupName,
                                    logLevel: "verbose",
                                    message: message,
                                    category: category,
                                    namespace: namespace)
    }
    
    /// - Given: a AWS CloudWatch Logging plugin with logging disabled
    /// - When: an error log message is logged and flushed
    /// - Then: the eror log message is not logged and sent to AWS CloudWatch
    func testFlushLogWithVerboseMessageAfterDisablingPlugin() async throws {
        let category = "Storage"
        let namespace = UUID().uuidString
        let message = "this is an verbose message in the integration test after disabling logging \(Date().epochMilliseconds)"
        let logger = Amplify.Logging.logger(forCategory: category, forNamespace: namespace)
        Amplify.Logging.disable()
        logger.verbose(message)
        let plugin = try Amplify.Logging.getPlugin(for: "awsCloudWatchLoggingPlugin")
        guard let loggingPlugin = plugin as? AWSCloudWatchLoggingPlugin else {
            XCTFail("Could not get plugin of type AWSCloudWatchLoggingPlugin")
            return
        }
        try await loggingPlugin.flushLogs()
        try await Task.sleep(seconds: 30)
        let cloudWatchClient = loggingPlugin.getEscapeHatch()
        try await verifyMessageNotSent(plugin: loggingPlugin,
                                       client: cloudWatchClient,
                                       logGroupName: loggingConfiguration?.logGroupName,
                                       message: message)
    }
    
    func verifyMessagesSent(plugin: AWSCloudWatchLoggingPlugin,
                            client: CloudWatchLogsClientProtocol?,
                            logGroupName: String?,
                            messageCount: Int,
                            message: String,
                            category: String,
                            namespace: String) async throws {

        let events = try await getLastMessageSent(
            plugin: plugin,
            client: client,
            logGroupName: logGroupName,
            expectedMessageCount: messageCount,
            message: message,
            requestAttempt: 0)
        XCTAssertEqual(events?.count, messageCount)
        guard let sentLogMessage = events?.first?.message else {
            XCTFail("Unable to verify last log message")
            return
        }
        XCTAssertTrue(sentLogMessage.contains(message))
        XCTAssertTrue(sentLogMessage.contains(category))
        XCTAssertTrue(sentLogMessage.contains(namespace))
    }
    
    func verifyMessageSent(plugin: AWSCloudWatchLoggingPlugin,
                           client: CloudWatchLogsClientProtocol?,
                           logGroupName: String?,
                           logLevel: String,
                           message: String,
                           category: String,
                           namespace: String) async throws {

        let events = try await getLastMessageSent(
            plugin: plugin,
            client: client,
            logGroupName: logGroupName,
            expectedMessageCount: 1,
            message: message,
            requestAttempt: 0)
        XCTAssertEqual(events?.count, 1)
        guard let sentLogMessage = events?.first?.message else {
            XCTFail("Unable to verify last log message")
            return
        }
        XCTAssertTrue(sentLogMessage.lowercased().contains(logLevel))
        XCTAssertTrue(sentLogMessage.contains(message))
        XCTAssertTrue(sentLogMessage.contains(category))
        XCTAssertTrue(sentLogMessage.contains(namespace))
    }
    
    func verifyMessageNotSent(plugin: AWSCloudWatchLoggingPlugin,
                              client: CloudWatchLogsClientProtocol?,
                              logGroupName: String?,
                              message: String) async throws {

        let events = try await getLastMessageSent(
            plugin: plugin,
            client: client,
            logGroupName: logGroupName,
            expectedMessageCount: 1,
            message: message,
            requestAttempt: 0)
        XCTAssertEqual(events?.count, 0)
    }
    
    func getLastMessageSent(plugin: AWSCloudWatchLoggingPlugin,
                            client: CloudWatchLogsClientProtocol?,
                            logGroupName: String?,
                            expectedMessageCount: Int,
                            message: String,
                            requestAttempt: Int) async throws -> [CloudWatchLogsClientTypes.FilteredLogEvent]? {
        let endTime = Date()
        let durationInMinutes = requestAttempt+1
        let startTime = endTime.addingTimeInterval(TimeInterval(-durationInMinutes*60))
        var events = try await AWSCloudWatchClientHelper.getFilterLogEventCount(client: client, filterPattern: message, startTime: startTime, endTime: endTime, logGroupName: logGroupName)
        
        if events?.count != expectedMessageCount && requestAttempt <= 5 {
            try await plugin.flushLogs()
            try await Task.sleep(seconds: 30)
            let attempted = requestAttempt + 1
            events = try await getLastMessageSent(
                plugin: plugin,
                client: client,
                logGroupName: logGroupName,
                expectedMessageCount: expectedMessageCount,
                message: message,
                requestAttempt: attempted)
        }
        
        return events
    }
}
