//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCloudWatchLoggingPlugin
import Amplify
import XCTest

final class AWSCloudWatchLoggingPluginConfigurationTests: XCTestCase {
    
    /// Given: a json file with the plugin configuration
    /// When: it is read from the bundle and decoded
    /// Then: AWSCloudWatchLoggingPluginConfiguration is created
    func testDecodeConfigurationFromJson() {
        let url = Bundle.module.url(forResource: "amplifyconfiguration_logging", withExtension: "json", subdirectory: "TestResources")

        
        guard let configUrl = url, let data = try? Data(contentsOf: configUrl) else {
            XCTFail("Unable to load test file")
            return
        }
        
        let jsonDecoder = JSONDecoder()
        guard let config = try? jsonDecoder.decode(AmplifyConfigurationLogging.self, from: data) else {
            XCTFail("Unable to deserialize object from json data")
            return
        }
        
        XCTAssertTrue(config.awsCloudWatchLoggingPlugin.enable)
        XCTAssertEqual(config.awsCloudWatchLoggingPlugin.defaultRemoteConfiguration?.endpoint.absoluteString, "http://www.amazon.com")
        XCTAssertEqual(config.awsCloudWatchLoggingPlugin.defaultRemoteConfiguration?.refreshIntervalInSeconds, 1200)
        XCTAssertEqual(config.awsCloudWatchLoggingPlugin.flushIntervalInSeconds, 60)
        XCTAssertEqual(config.awsCloudWatchLoggingPlugin.localStoreMaxSizeInMB, 5)
        XCTAssertEqual(config.awsCloudWatchLoggingPlugin.logGroupName, "testLogGroup")
        XCTAssertEqual(config.awsCloudWatchLoggingPlugin.region, "us-east-1")
        XCTAssertEqual(config.awsCloudWatchLoggingPlugin.loggingConstraints.defaultLogLevel.rawValue, LogLevel.error.rawValue)
        XCTAssertEqual(config.awsCloudWatchLoggingPlugin.loggingConstraints.categoryLogLevel?.count, 2)
        XCTAssertEqual(config.awsCloudWatchLoggingPlugin.loggingConstraints.userLogLevel?.count, 1)
    }

    /// Given: a json file with the remote logging constraints defined
    /// When: it is read from the bundle and decoded
    /// Then: LoggingConstraints is created
    func testRemoteLoggingConstraintsDeserialization() {
        let url = Bundle.module.url(forResource: "remoteloggingconstraints", withExtension: "json", subdirectory: "TestResources")

        
        guard let configUrl = url, let data = try? Data(contentsOf: configUrl) else {
            XCTFail("Unable to load test file")
            return
        }
        guard let loggingConstraints = try? JSONDecoder().decode(LoggingConstraints.self, from: data) else {
            XCTFail("Unable to decode from data")
            return
        }
        XCTAssertEqual(loggingConstraints.defaultLogLevel.rawValue, LogLevel.error.rawValue)
        XCTAssertEqual(loggingConstraints.categoryLogLevel?.count, 4)
        XCTAssertEqual(loggingConstraints.userLogLevel?.count, 2)
        XCTAssertEqual(loggingConstraints.userLogLevel?["sub1"]?.defaultLogLevel.rawValue, LogLevel.info.rawValue)
    }
}
