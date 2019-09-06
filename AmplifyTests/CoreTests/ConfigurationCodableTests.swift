//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

/// For these tests, be sure to cast any concrete objects as the appropriate configuration protocol, to ensure the
/// *protocols* are Codable, not the implementing types
class ConfigurationCodableTests: XCTestCase {
    func testAmplifyConfigurationIsCodable() {
        let config = BasicAmplifyConfiguration() as AmplifyConfiguration
        XCTAssertTrue(config is Codable)
    }

    func testCategoryConfigurationIsCodable() {
        let config = BasicCategoryConfiguration(plugins: [:]) as CategoryConfiguration
        XCTAssertTrue(config is Codable)
    }
}
