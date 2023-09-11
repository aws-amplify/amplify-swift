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

    func testGetEscapeHatch() throws {
        let plugin = try Amplify.Logging.getPlugin(for: "awsCloudWatchLoggingPlugin")
        guard let loggingPlugin = plugin as? AWSCloudWatchLoggingPlugin else {
            XCTFail("Could not get plugin of type AWSCloudWatchLoggingPlugin")
            return
        }
        let cloudWatchClient = loggingPlugin.getEscapeHatch()
        XCTAssertNotNil(cloudWatchClient)
    }
    
    func testFlushLog() async throws {
        let category = "Analytics"
        let namespace = "Integration"
        let message = "this is an error message in the integration test"
        let logger = Amplify.Logging.logger(forCategory: category, forNamespace: namespace)
        logger.error(message)
        let plugin = try Amplify.Logging.getPlugin(for: "awsCloudWatchLoggingPlugin")
        guard let loggingPlugin = plugin as? AWSCloudWatchLoggingPlugin else {
            XCTFail("Could not get plugin of type AWSCloudWatchLoggingPlugin")
            return
        }
        try await loggingPlugin.flushLogs()
        try await Task.sleep(seconds: 15)
        let cloudWatchClient = loggingPlugin.getEscapeHatch()
        try await verifyMessageSent(client: cloudWatchClient,
                                    logGroupName: loggingConfiguration?.logGroupName,
                                    message: message,
                                    category: category,
                                    namespace: namespace)
    }
    
    func verifyMessageSent(client: CloudWatchLogsClientProtocol?,
                           logGroupName: String?,
                           message: String,
                           category: String,
                           namespace: String) async throws {

        let events = try await getLastMessageSent(client: client, logGroupName: logGroupName, message: message, requestAttempt: 0)
        XCTAssertEqual(events?.count, 1)
        guard let sentLogMessage = events?.first?.message else {
            XCTFail("Unable to verify last log message")
            return
        }
        print(sentLogMessage)
        XCTAssertTrue(sentLogMessage.contains(message))
        XCTAssertTrue(sentLogMessage.contains(category))
        XCTAssertTrue(sentLogMessage.contains(namespace))
    }
    
    func getLastMessageSent(client: CloudWatchLogsClientProtocol?,
                            logGroupName: String?,
                            message: String,
                            requestAttempt: Int) async throws -> [CloudWatchLogsClientTypes.FilteredLogEvent]? {
        let startTime = Date().addingTimeInterval(TimeInterval(-2*60))
        let endTime = Date()
        
        var events = try await AWSCloudWatchClientHelper.getFilterLogEventCount(client: client, filterPattern: message, startTime: startTime, endTime: endTime, logGroupName: logGroupName)
        
        if events?.count == 0 && requestAttempt <= 3 {
            try await Task.sleep(seconds: 15)
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
