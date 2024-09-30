//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSSDKSwiftCLI
import AWSCLIUtils
import XCTest

class VersionUtilsTests: XCTestCase {
    
    func testIncrementingMajor() throws {
        try XCTAssertEqual(
            Version("1.2.1").incrementingMajor(),
            Version("2.0.0")
        )
    }
    
    func testIncrementingMinor() throws {
        try XCTAssertEqual(
            Version("1.2.1").incrementingMinor(),
            Version("1.3.0")
        )
    }
    
    func testIncrementingPatch() throws {
        try XCTAssertEqual(
            Version("1.2.1").incrementingPatch(),
            Version("1.2.2")
        )
    }
}
