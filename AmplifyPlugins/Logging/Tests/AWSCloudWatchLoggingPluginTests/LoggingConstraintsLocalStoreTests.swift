//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

@testable import AWSCloudWatchLoggingPlugin

final class LoggingConstraintsLocalStoreTests: XCTestCase {
    
    override func setUp() async throws {
        UserDefaults.standard.removeObject(forKey: PluginConstants.awsRemoteLoggingConstraintsKey)
        UserDefaults.standard.removeObject(forKey: PluginConstants.awsRemoteLoggingConstraintsTagKey)
    }
    
    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: PluginConstants.awsRemoteLoggingConstraintsKey)
        UserDefaults.standard.removeObject(forKey: PluginConstants.awsRemoteLoggingConstraintsTagKey)
    }
    
    /// Given: no remote constraints are cached in UserDefaults
    /// When: logging constraints are accessed via the LoggingConstraintsLocalStore
    /// Then: the LoggingConstraintsLocalStore returns nil
    func testNoDataCached() {
        let localStore: LoggingConstraintsLocalStore = UserDefaults.standard
        XCTAssertNil(localStore.getLocalLoggingConstraints())
        XCTAssertNil(localStore.getLocalLoggingConstraintsEtag())
    }
    
    /// Given: UserDefaults contains an etag and a default logging constraints
    /// When: logging constraints are accessed via the LoggingConstraintsLocalStore
    /// Then: the LoggingConstraintsLocalStore returns the cached etag and default LoggingConstraints
    func testSetCacheDataWithEmptyLoggingConstraints() {
        let localStore: LoggingConstraintsLocalStore = UserDefaults.standard
        XCTAssertNil(localStore.getLocalLoggingConstraints())
        XCTAssertNil(localStore.getLocalLoggingConstraintsEtag())
        localStore.setLocalLoggingConstraintsEtag(etag: "testString")
        let loggingConstraints = LoggingConstraints()
        localStore.setLocalLoggingConstraints(loggingConstraints: loggingConstraints)
        
        XCTAssertEqual(localStore.getLocalLoggingConstraintsEtag(), "testString")
        XCTAssertEqual(localStore.getLocalLoggingConstraints()!.defaultLogLevel.rawValue, 0)
        XCTAssertTrue(localStore.getLocalLoggingConstraints()!.categoryLogLevel!.isEmpty)
        XCTAssertTrue(localStore.getLocalLoggingConstraints()!.userLogLevel!.isEmpty)
    }
    
    /// Given: UserDefaults contains an etag and a valid logging constraints
    /// When: logging constraints are accessed via the LoggingConstraintsLocalStore
    /// Then: the LoggingConstraintsLocalStore returns the cached etag and valid LoggingConstraints
    func testSetCacheDataWithValidLoggingConstraints() {
        let localStore: LoggingConstraintsLocalStore = UserDefaults.standard
        XCTAssertNil(localStore.getLocalLoggingConstraints())
        XCTAssertNil(localStore.getLocalLoggingConstraintsEtag())
        localStore.setLocalLoggingConstraintsEtag(etag: "testString")
        let loggingConstraints = LoggingConstraints(defaultLogLevel: .warn, categoryLogLevel: ["Auth": .debug])
        localStore.setLocalLoggingConstraints(loggingConstraints: loggingConstraints)
        
        XCTAssertEqual(localStore.getLocalLoggingConstraintsEtag(), "testString")
        XCTAssertEqual(localStore.getLocalLoggingConstraints()?.defaultLogLevel.rawValue, 1)
        XCTAssertEqual(localStore.getLocalLoggingConstraints()!.categoryLogLevel!.count, 1)
        XCTAssertTrue(localStore.getLocalLoggingConstraints()!.userLogLevel!.isEmpty)
    }
}
