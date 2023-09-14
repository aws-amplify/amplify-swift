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
    let amplifyConfigurationLoggingFile = "testconfiguration/AWSCloudWatchLoggingPluginIntegrationTests-amplifyconfiguration_logging"
    var loggingConfiguration: AWSCloudWatchLoggingPluginConfiguration?
    
    override func setUp() async throws {
        continueAfterFailure = false
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            let loggingConfigurationFile = try TestConfigHelper.retrieveLoggingConfiguration(forResource: amplifyConfigurationLoggingFile)
            loggingConfiguration = try AWSCloudWatchLoggingPluginConfiguration.loadConfiguration(from: loggingConfigurationFile)
            let loggingPlugin = AWSCloudWatchLoggingPlugin(loggingPluginConfiguration: loggingConfiguration)
            try Amplify.add(plugin: loggingPlugin)
            let configuration = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: amplifyConfigurationFile)
            try Amplify.configure(configuration)
            try await Task.sleep(seconds: 2)
        } catch {
            XCTFail("Failed to initialize and configure Amplify: \(error)")
        }
        XCTAssertNotNil(Amplify.Auth.plugin)
        XCTAssertTrue(Amplify.Auth.isConfigured)
    }

    override func tearDown() async throws {
        await Amplify.reset()
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
    /// - When: an error log message is logged and flushed
    /// - Then: the error log message is logged and sent to AWS CloudWatch
    func testFlushLogWithErrorMessage() async throws {
        let category = "Analytics"
        let namespace = UUID().uuidString
        let message = "this is an error message in the integration test"
        let logger = Amplify.Logging.logger(forCategory: category, forNamespace: namespace)
        logger.error(message)
        let plugin = try Amplify.Logging.getPlugin(for: "awsCloudWatchLoggingPlugin")
        guard let loggingPlugin = plugin as? AWSCloudWatchLoggingPlugin else {
            XCTFail("Could not get plugin of type AWSCloudWatchLoggingPlugin")
            return
        }
        try await loggingPlugin.flushLogs()
        try await Task.sleep(seconds: 30)
        let cloudWatchClient = loggingPlugin.getEscapeHatch()
        try await verifyMessageSent(client: cloudWatchClient,
                                    logGroupName: loggingConfiguration?.logGroupName,
                                    logLevel: "error",
                                    message: message,
                                    category: category,
                                    namespace: namespace)
    }
    
    /// - Given: a AWS CloudWatch Logging plugin
    /// - When: an warn log message is logged and flushed
    /// - Then: the warn log message is logged and sent to AWS CloudWatch
    func testFlushLogWithWarnMessage() async throws {
        let category = "API"
        let namespace = UUID().uuidString
        let message = "this is an warn message in the integration test"
        let logger = Amplify.Logging.logger(forCategory: category, forNamespace: namespace)
        logger.warn(message)
        let plugin = try Amplify.Logging.getPlugin(for: "awsCloudWatchLoggingPlugin")
        guard let loggingPlugin = plugin as? AWSCloudWatchLoggingPlugin else {
            XCTFail("Could not get plugin of type AWSCloudWatchLoggingPlugin")
            return
        }
        try await loggingPlugin.flushLogs()
        try await Task.sleep(seconds: 30)
        let cloudWatchClient = loggingPlugin.getEscapeHatch()
        try await verifyMessageSent(client: cloudWatchClient,
                                    logGroupName: loggingConfiguration?.logGroupName,
                                    logLevel: "warn",
                                    message: message,
                                    category: category,
                                    namespace: namespace)
    }
    
    /// - Given: a AWS CloudWatch Logging plugin
    /// - When: an debug log message is logged and flushed
    /// - Then: the debug log message is logged and sent to AWS CloudWatch
    func testFlushLogWithDebugMessage() async throws {
        let category = "Geo"
        let namespace = UUID().uuidString
        let message = "this is an debug message in the integration test"
        let logger = Amplify.Logging.logger(forCategory: category, forNamespace: namespace)
        logger.debug(message)
        let plugin = try Amplify.Logging.getPlugin(for: "awsCloudWatchLoggingPlugin")
        guard let loggingPlugin = plugin as? AWSCloudWatchLoggingPlugin else {
            XCTFail("Could not get plugin of type AWSCloudWatchLoggingPlugin")
            return
        }
        try await loggingPlugin.flushLogs()
        try await Task.sleep(seconds: 30)
        let cloudWatchClient = loggingPlugin.getEscapeHatch()
        try await verifyMessageSent(client: cloudWatchClient,
                                    logGroupName: loggingConfiguration?.logGroupName,
                                    logLevel: "debug",
                                    message: message,
                                    category: category,
                                    namespace: namespace)
    }
    
    /// - Given: a AWS CloudWatch Logging plugin
    /// - When: an info log message is logged and flushed
    /// - Then: the info log message is logged and sent to AWS CloudWatch
    func testFlushLogWithInfoMessage() async throws {
        let category = "Auth"
        let namespace = UUID().uuidString
        let message = "this is an info message in the integration test"
        let logger = Amplify.Logging.logger(forCategory: category, forNamespace: namespace)
        logger.info(message)
        let plugin = try Amplify.Logging.getPlugin(for: "awsCloudWatchLoggingPlugin")
        guard let loggingPlugin = plugin as? AWSCloudWatchLoggingPlugin else {
            XCTFail("Could not get plugin of type AWSCloudWatchLoggingPlugin")
            return
        }
        try await loggingPlugin.flushLogs()
        try await Task.sleep(seconds: 30)
        let cloudWatchClient = loggingPlugin.getEscapeHatch()
        try await verifyMessageSent(client: cloudWatchClient,
                                    logGroupName: loggingConfiguration?.logGroupName,
                                    logLevel: "info",
                                    message: message,
                                    category: category,
                                    namespace: namespace)
    }
    
    /// - Given: a AWS CloudWatch Logging plugin
    /// - When: an verbose log message is logged and flushed
    /// - Then: the verbose log message is logged and sent to AWS CloudWatch
    func testFlushLogWithVerboseMessage() async throws {
        let category = "Datastore"
        let namespace = UUID().uuidString
        let message = "this is an verbose message in the integration test"
        let logger = Amplify.Logging.logger(forCategory: category, forNamespace: namespace)
        logger.verbose(message)
        let plugin = try Amplify.Logging.getPlugin(for: "awsCloudWatchLoggingPlugin")
        guard let loggingPlugin = plugin as? AWSCloudWatchLoggingPlugin else {
            XCTFail("Could not get plugin of type AWSCloudWatchLoggingPlugin")
            return
        }
        try await loggingPlugin.flushLogs()
        try await Task.sleep(seconds: 30)
        let cloudWatchClient = loggingPlugin.getEscapeHatch()
        try await verifyMessageSent(client: cloudWatchClient,
                                    logGroupName: loggingConfiguration?.logGroupName,
                                    logLevel: "verbose",
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
        let message = "this is an verbose message in the integration test after enabling logging"
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
        try await verifyMessageSent(client: cloudWatchClient,
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
        let category = "Push Notifications"
        let namespace = UUID().uuidString
        let message = "this is an verbose message in the integration test after disabling logging"
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
        try await verifyMessageNotSent(client: cloudWatchClient,
                                       logGroupName: loggingConfiguration?.logGroupName,
                                       message: message)
    }
    
    func verifyMessageSent(client: CloudWatchLogsClientProtocol?,
                           logGroupName: String?,
                           logLevel: String,
                           message: String,
                           category: String,
                           namespace: String) async throws {

        let events = try await getLastMessageSent(client: client, logGroupName: logGroupName, message: message, requestAttempt: 0)
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
    
    func verifyMessageNotSent(client: CloudWatchLogsClientProtocol?,
                              logGroupName: String?,
                              message: String) async throws {

        let events = try await getLastMessageSent(client: client, logGroupName: logGroupName, message: message, requestAttempt: 0)
        XCTAssertEqual(events?.count, 0)
    }
    
    func getLastMessageSent(client: CloudWatchLogsClientProtocol?,
                            logGroupName: String?,
                            message: String,
                            requestAttempt: Int) async throws -> [CloudWatchLogsClientTypes.FilteredLogEvent]? {
        let startTime = Date().addingTimeInterval(TimeInterval(-3*60))
        let endTime = Date()
        
        var events = try await AWSCloudWatchClientHelper.getFilterLogEventCount(client: client, filterPattern: message, startTime: startTime, endTime: endTime, logGroupName: logGroupName)
        
        if events?.count == 0 && requestAttempt <= 3 {
            try await Task.sleep(seconds: 30)
            let attempted = requestAttempt + 1
            events = try await getLastMessageSent(
                client: client,
                logGroupName: logGroupName,
                message: message,
                requestAttempt: attempted)
        }
        
        return events
    }
}
