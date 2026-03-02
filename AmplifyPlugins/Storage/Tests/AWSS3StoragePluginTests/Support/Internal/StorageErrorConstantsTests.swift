//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSS3StoragePlugin

class StorageErrorConstantsTests: XCTestCase {

    /// Given: makeProgressStallTimeoutError is called
    /// When: The returned NSError is inspected
    /// Then: Domain is AWSS3TransferUtilityErrorDomain, code is 10, description contains progress stall message
    func testMakeProgressStallTimeoutError_returnsCorrectNSError() {
        let error = makeProgressStallTimeoutError()

        XCTAssertEqual(error.domain, AWSS3TransferUtilityErrorDomain)
        XCTAssertEqual(error.code, AWSS3TransferUtilityErrorProgressStallTimeout)
        XCTAssertEqual(error.code, 10)
        XCTAssertTrue(
            error.localizedDescription.contains("progress did not advance"),
            "Expected description to mention progress stall, got: \(error.localizedDescription)"
        )
        XCTAssertTrue(
            error.localizedDescription.contains("timeout"),
            "Expected description to mention timeout, got: \(error.localizedDescription)"
        )
    }

    /// Given: AWSS3TransferUtilityErrorDomain and AWSS3TransferUtilityErrorProgressStallTimeout
    /// When: Values are used
    /// Then: They match the expected constants
    func testProgressStallTimeoutConstants_haveExpectedValues() {
        XCTAssertEqual(AWSS3TransferUtilityErrorDomain, "com.amazonaws.AWSS3TransferUtilityErrorDomain")
        XCTAssertEqual(AWSS3TransferUtilityErrorProgressStallTimeout, 10)
    }
}
