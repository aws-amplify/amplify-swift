//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

@testable import AWSCloudWatchLoggingPlugin

final class DefaultRemoteConfigurationTests: XCTestCase {
    
    /// Given: DefaultRemoteConfiguration
    /// When: it is constructed with parameters
    /// Then: instance is created with the specified parameters
    func testConstructor() {
        let url = URL(string: "http://www.amazon.com")
        let defaultRemoteConfiguration = DefaultRemoteConfiguration(endpoint: url!, refreshIntervalInSeconds: 100)
        
        XCTAssertEqual(defaultRemoteConfiguration.refreshIntervalInSeconds, 100)
        XCTAssertEqual(defaultRemoteConfiguration.endpoint.absoluteString, url?.absoluteString)
    }
}
