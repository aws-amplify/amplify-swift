//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest
@testable import AWSS3StoragePlugin

class StorageConfigurationTests: XCTestCase {

    /// Given: StorageConfiguration with default init
    /// When: progressStallTimeout is read
    /// Then: It is none (disabled)
    func testDefaultProgressStallTimeoutIsNone() {
        let config = StorageConfiguration()
        XCTAssertEqual(config.progressStallTimeout, .disabled)
    }

    /// Given: StorageConfiguration init with progressStallTimeout
    /// When: Created with custom value
    /// Then: progressStallTimeout is stored correctly
    func testProgressStallTimeout_customValue() {
        let config = StorageConfiguration(progressStallTimeout: .interval(30))
        XCTAssertEqual(config.progressStallTimeout, .interval(30))
    }

    /// Given: StorageConfiguration init forBucket with progressStallTimeout
    /// When: Created for a bucket
    /// Then: progressStallTimeout is stored correctly
    func testForBucketProgressStallTimeout() {
        let config = StorageConfiguration(forBucket: "test-bucket", progressStallTimeout: .interval(60))
        XCTAssertEqual(config.progressStallTimeout, .interval(60))
        XCTAssertTrue(config.sessionIdentifier.contains("test-bucket"))
    }
}
