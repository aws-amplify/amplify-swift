//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSS3StoragePlugin

class StorageConfigurationTests: XCTestCase {

    /// Given: StorageConfiguration with default init
    /// When: progressStallTimeoutInterval is read
    /// Then: It is 0 (disabled)
    func testDefaultProgressStallTimeoutInterval_isZero() {
        let config = StorageConfiguration()
        XCTAssertEqual(config.progressStallTimeoutInterval, 0)
    }

    /// Given: StorageConfiguration init with progressStallTimeoutInterval
    /// When: Created with custom value
    /// Then: progressStallTimeoutInterval is stored correctly
    func testProgressStallTimeoutInterval_customValue() {
        let config = StorageConfiguration(progressStallTimeoutInterval: 30)
        XCTAssertEqual(config.progressStallTimeoutInterval, 30)
    }

    /// Given: StorageConfiguration init forBucket with progressStallTimeoutInterval
    /// When: Created for a bucket
    /// Then: progressStallTimeoutInterval is stored correctly
    func testForBucketProgressStallTimeoutInterval() {
        let config = StorageConfiguration(forBucket: "test-bucket", progressStallTimeoutInterval: 60)
        XCTAssertEqual(config.progressStallTimeoutInterval, 60)
        XCTAssertTrue(config.sessionIdentifier.contains("test-bucket"))
    }
}
