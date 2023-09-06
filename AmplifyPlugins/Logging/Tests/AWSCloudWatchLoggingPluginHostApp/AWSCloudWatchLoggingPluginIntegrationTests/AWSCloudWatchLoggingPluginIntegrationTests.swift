//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSLocation

@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSCloudWatchLoggingPlugin

class AWSCloudWatchLoggingPluginIntergrationTests: XCTestCase {
    let amplifyConfigurationFile = "testconfiguration/AWSCloudWatchLoggingPluginIntegrationTests-amplifyconfiguration"
    let amplifyConfigurationLoggingFile = "testconfiguration/AWSCloudWatchLoggingPluginIntegrationTests-amplifyconfiguration-logging.json"
    
    override func setUp() {
        continueAfterFailure = false
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            let loggingConstraints = LoggingConstraints(defaultLogLevel: .error)
            let loggingConfiguration = AWSCloudWatchLoggingPluginConfiguration(logGroupName: "579633542375-remote-logging-group", region: "us-east-1", localStoreMaxSizeInMB: 1, flushIntervalInSeconds: 60, loggingConstraints: loggingConstraints)
            let loggingPlugin = AWSCloudWatchLoggingPlugin(loggingPluginConfiguration: loggingConfiguration)
            try Amplify.add(plugin: loggingPlugin)
            let configuration = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: amplifyConfigurationFile)
            try Amplify.configure(configuration)
        } catch {
            XCTFail("Failed to initialize and configure Amplify: \(error)")
        }
        XCTAssertNotNil(Amplify.Auth.plugin)
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
}
