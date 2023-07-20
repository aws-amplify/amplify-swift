//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

@testable import AWSCloudWatchLoggingPlugin

final class AWSCloudWatchLoggingFilterTests: XCTestCase {
    var configuration: AWSCloudWatchLoggingPluginConfiguration!
    var filter: AWSCloudWatchLoggingFilter!
    var remoteLoggingConstraints: LoggingConstraints!
    
    override func setUp() async throws {
        let configUrl = Bundle.module.url(forResource: "amplifyconfiguration_logging", withExtension: "json", subdirectory: "TestResources")
        configuration = try AWSCloudWatchLoggingPluginConfiguration.loadConfiguration(from: configUrl!)
        
        let resolver = AWSCloudWatchLoggingConstraintsResolver(loggingPluginConfiguration: configuration!)
        filter = AWSCloudWatchLoggingFilter(loggingConstraintsResolver: resolver)
        
        let remoteUrl = Bundle.module.url(forResource: "remoteloggingconstraints", withExtension: "json", subdirectory: "TestResources")
        let data = try Data(contentsOf: remoteUrl!)
        remoteLoggingConstraints = try JSONDecoder().decode(LoggingConstraints.self, from: data)
    }
    
    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: PluginConstants.awsRemoteLoggingConstraintsKey)
        configuration = nil
        filter = nil
        remoteLoggingConstraints = nil
    }
    
    /// Given: the local logging constraints configuration that enables logging
    /// When: `canLog` is called from AWSCloudWatchLoggingFilter
    /// Then: canLog returns true
    func testDefaultsToLocalConfigurationCanLog() {
        XCTAssertTrue(filter.canLog(withCategory: "AUTH", logLevel: .error, userIdentifier: nil))
        XCTAssertTrue(filter.canLog(withCategory: "API", logLevel: .error, userIdentifier: nil))
        XCTAssertTrue(filter.canLog(withCategory: "STORAGE", logLevel: .error, userIdentifier: nil))
        
        XCTAssertTrue(filter.canLog(withCategory: "API", logLevel: .warn, userIdentifier: nil))
        XCTAssertTrue(filter.canLog(withCategory: "STORAGE", logLevel: .warn, userIdentifier: nil))
        
        XCTAssertTrue(filter.canLog(withCategory: "API", logLevel: .info, userIdentifier: "cognitoSub1"))
        XCTAssertTrue(filter.canLog(withCategory: "STORAGE", logLevel: .info, userIdentifier: "cognitoSub1"))
        
        XCTAssertTrue(filter.canLog(withCategory: "API", logLevel: .warn, userIdentifier: "cognitoSub2"))
        XCTAssertTrue(filter.canLog(withCategory: "STORAGE", logLevel: .warn, userIdentifier: "cognitoSub2"))
    }
    
    /// Given: the local logging constraints configuration that disables logging
    /// When: `canLog` is called from AWSCloudWatchLoggingFilter
    /// Then: `canLog` returns false
    func testDefaultsToLocalConfigurationCannotLog() {
        XCTAssertFalse(filter.canLog(withCategory: "AUTH", logLevel: .warn, userIdentifier: nil))
        XCTAssertFalse(filter.canLog(withCategory: "API", logLevel: .info, userIdentifier: nil))
        XCTAssertFalse(filter.canLog(withCategory: "STORAGE", logLevel: .info, userIdentifier: nil))
        
        XCTAssertFalse(filter.canLog(withCategory: "AUTH", logLevel: .info, userIdentifier: "cognitoSub1"))
        XCTAssertFalse(filter.canLog(withCategory: "API", logLevel: .verbose, userIdentifier: "cognitoSub1"))
        XCTAssertFalse(filter.canLog(withCategory: "STORAGE", logLevel: .verbose, userIdentifier: "cognitoSub1"))
        
        XCTAssertFalse(filter.canLog(withCategory: "AUTH", logLevel: .warn, userIdentifier: "cognitoSub2"))
        XCTAssertFalse(filter.canLog(withCategory: "API", logLevel: .info, userIdentifier: "cognitoSub2"))
        XCTAssertFalse(filter.canLog(withCategory: "STORAGE", logLevel: .info, userIdentifier: "cognitoSub2"))
    }
    
    /// Given: the remote logging constraints configuration that enables logging
    /// When: `canLog` is called from AWSCloudWatchLoggingFilter
    /// Then: `canLog` returns true
    func testDefaultsToRemoteConfigurationCanLog() {
        let localStore = UserDefaults.standard
        localStore.setLocalLoggingConstraints(loggingConstraints: self.remoteLoggingConstraints)
        let resolver = AWSCloudWatchLoggingConstraintsResolver(loggingPluginConfiguration: self.configuration, loggingConstraintsLocalStore: localStore)
        filter = AWSCloudWatchLoggingFilter(loggingConstraintsResolver: resolver)
        
        XCTAssertTrue(filter.canLog(withCategory: "ANALYTICS", logLevel: .error, userIdentifier: nil))
        
        XCTAssertTrue(filter.canLog(withCategory: "DATASTORE", logLevel: .warn, userIdentifier: "cognitoSub1"))
        XCTAssertTrue(filter.canLog(withCategory: "DATASTORE", logLevel: .info, userIdentifier: "cognitoSub1"))
        XCTAssertTrue(filter.canLog(withCategory: "STORAGE", logLevel: .warn, userIdentifier: "cognitoSub1"))
        XCTAssertTrue(filter.canLog(withCategory: "STORAGE", logLevel: .debug, userIdentifier: "cognitoSub1"))
        
        XCTAssertTrue(filter.canLog(withCategory: "AUTH", logLevel: .error, userIdentifier: "sub1"))
        XCTAssertTrue(filter.canLog(withCategory: "AUTH", logLevel: .warn, userIdentifier: "sub1"))
        XCTAssertTrue(filter.canLog(withCategory: "AUTH", logLevel: .info, userIdentifier: "sub1"))
        
        XCTAssertTrue(filter.canLog(withCategory: "AUTH", logLevel: .error, userIdentifier: "sub3"))
        XCTAssertTrue(filter.canLog(withCategory: "AUTH", logLevel: .warn, userIdentifier: "sub3"))
        XCTAssertTrue(filter.canLog(withCategory: "AUTH", logLevel: .info, userIdentifier: "sub3"))
        
        XCTAssertTrue(filter.canLog(withCategory: "STORAGE", logLevel: .error, userIdentifier: "sub3"))
        XCTAssertTrue(filter.canLog(withCategory: "STORAGE", logLevel: .warn, userIdentifier: "sub3"))
        XCTAssertTrue(filter.canLog(withCategory: "STORAGE", logLevel: .info, userIdentifier: "sub3"))
        
    }
    
    /// Given: the remote logging constraints configuration that disables logging
    /// When: `canLog` is called from AWSCloudWatchLoggingFilter
    /// Then: `canLog` returns false
    func testDefaultsToRemoteConfigurationCannotLog() {
        let localStore = UserDefaults.standard
        localStore.setLocalLoggingConstraints(loggingConstraints: self.remoteLoggingConstraints)
        let resolver = AWSCloudWatchLoggingConstraintsResolver(loggingPluginConfiguration: self.configuration, loggingConstraintsLocalStore: localStore)
        filter = AWSCloudWatchLoggingFilter(loggingConstraintsResolver: resolver)
        
        
        XCTAssertFalse(filter.canLog(withCategory: "ANALYTICS", logLevel: .warn, userIdentifier: nil))
        XCTAssertFalse(filter.canLog(withCategory: "AUTH", logLevel: .verbose, userIdentifier: nil))
        XCTAssertFalse(filter.canLog(withCategory: "API", logLevel: .warn, userIdentifier: nil))
        
        XCTAssertFalse(filter.canLog(withCategory: "DATASTORE", logLevel: .verbose, userIdentifier: "cognitoSub1"))
        XCTAssertFalse(filter.canLog(withCategory: "STORAGE", logLevel: .verbose, userIdentifier: "cognitoSub1"))
        
        XCTAssertFalse(filter.canLog(withCategory: "AUTH", logLevel: .verbose, userIdentifier: "sub1"))
        XCTAssertFalse(filter.canLog(withCategory: "API", logLevel: .error, userIdentifier: "sub1"))
        XCTAssertFalse(filter.canLog(withCategory: "STORAGE", logLevel: .error, userIdentifier: "sub1"))
        
        XCTAssertFalse(filter.canLog(withCategory: "AUTH", logLevel: .verbose, userIdentifier: "sub3"))
        XCTAssertFalse(filter.canLog(withCategory: "API", logLevel: .error, userIdentifier: "sub3"))
        XCTAssertFalse(filter.canLog(withCategory: "STORAGE", logLevel: .verbose, userIdentifier: "sub3"))
    }
}
