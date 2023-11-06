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
    
    /// Given: a AWSCloudWatchLoggingPluginConfiguration
    /// When: AWSCloudWatchLoggingPlugin is constructed
    /// Then: the configuration can be specified as a parameter
    func testPluginConstructor() throws {
        let configuration = AWSCloudWatchLoggingPluginConfiguration(logGroupName: "testLogGroup", region: "us-east-1")
        let plugin = AWSCloudWatchLoggingPlugin(loggingPluginConfiguration: configuration)
        XCTAssertNotNil(plugin.loggingClient)
        XCTAssertEqual(plugin.key, PluginConstants.awsCloudWatchLoggingPluginKey)
    }
    
    /// Given: a AWSCloudWatchLoggingPlugin
    /// When: a logger is requested
    /// Then: loggers a returned
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
    
    /// Given: a AWSCloudWatchLoggingPlugin
    /// When: a logger is requested with a namespace
    /// Then: the namespace is set in the logger session controller
    func testPluginLoggerNamespace() throws {
        let configuration = AWSCloudWatchLoggingPluginConfiguration(logGroupName: "testLogGroup", region: "us-east-1")
        let plugin = AWSCloudWatchLoggingPlugin(loggingPluginConfiguration: configuration)
        _ = plugin.logger(forCategory: "Category1")
        var sessionController = plugin.loggingClient.getLoggerSessionController(forCategory: "Category1", logLevel: .error)
        XCTAssertEqual(sessionController?.namespace, nil)
        
        _ = plugin.logger(forCategory: "Category2", forNamespace: "testNamespace")
        sessionController = plugin.loggingClient.getLoggerSessionController(forCategory: "Category2", logLevel: .error)
        XCTAssertEqual(sessionController?.namespace, "testNamespace")
        
    }
}
