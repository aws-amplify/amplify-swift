//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSS3StoragePlugin

class AWSS3StoragePluginConfigureTests: AWSS3StoragePluginTests {

    // MARK: configuration tests
    func testConfigure() throws {
        let bucket = JSONValue.init(stringLiteral: testBucket)
        let region = JSONValue.init(stringLiteral: testRegion)
        let storagePluginConfig = JSONValue.init(
            dictionaryLiteral: (PluginConstants.Bucket, bucket), (PluginConstants.Region, region))

        do {
            try storagePlugin.configure(using: storagePluginConfig)
        } catch {
            XCTFail("Failed to configure storage plugin")
        }
    }

    func testConfigureWithDefaultAccessLevelWithOverrideRequestAccessLevelOnAPICalls() {
        XCTFail("Not yet implemented")
    }

    func testConfigureThrowsErrorForMissingBucket() {
        XCTFail("Not yet implemented")
    }

    func testConfigureThrowsForEmptyBucket() {
        XCTFail("Not yet implemented")
    }

    func testConfigureThrowsErrorForMissingRegion() {
        XCTFail("Not yet implemented")
    }

    func testConfigureThrowsForEmptyRegion() {
        XCTFail("Not yet implemented")
    }

    func testConfigureThrowsForInvalidRegion() {
        XCTFail("Not yet implemented")
    }

    func testConfigureThrowsForInvalidDefaultAccessLevel() {
        XCTFail("Not yet implemented")
    }

    func testConfigureThrowsForSpecifiedAndEmptyDefaultAccessLevel() {
        XCTFail("Not yet implemented")
    }


}
