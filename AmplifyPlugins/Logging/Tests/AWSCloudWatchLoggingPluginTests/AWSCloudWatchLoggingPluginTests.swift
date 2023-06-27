//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCloudWatchLoggingPlugin

import XCTest

final class AWSCloudWatchLoggingPluginTests: XCTestCase {
    
    func testDefaultPluginConstructor() throws {
        let plugin = AWSCloudWatchLoggingPlugin()
        XCTAssertEqual(plugin.key, PluginConstants.awsCloudWatchLoggingPluginKey)
    }
    
    func testPluginConstructor() throws {
        let configuration = AWSCloudWatchLoggingPluginConfiguration(logGroupName: "testLogGroup", region: "us-east-1")
        let plugin = AWSCloudWatchLoggingPlugin(loggingPluginConfiguration: configuration)
        XCTAssertNotNil(plugin.loggingClient)
        XCTAssertEqual(plugin.key, PluginConstants.awsCloudWatchLoggingPluginKey)
    }
    
    func testPluginLoggers() throws {
        let configuration = AWSCloudWatchLoggingPluginConfiguration(logGroupName: "testLogGroup", region: "us-east-1")
        let plugin = AWSCloudWatchLoggingPlugin(loggingPluginConfiguration: configuration)
        var authLogger = plugin.logger(forCategory: "Auth")
        XCTAssertEqual(authLogger.logLevel.rawValue, 0)
        
        authLogger = plugin.logger(forCategory: "Auth", forNamespace: "test")
        XCTAssertEqual(authLogger.logLevel.rawValue, 0)

        let apiLogger = plugin.logger(forCategory: "API", logLevel: .debug)
        XCTAssertEqual(apiLogger.logLevel.rawValue, 3)

        let defaultLogger = plugin.logger(forNamespace: "test")
        XCTAssertEqual(defaultLogger.logLevel.rawValue, 0)

    }
}
