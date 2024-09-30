//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSClientRuntime
import XCTest

class InternalMetadataTests: XCTestCase {

    func test_description_returnsMDInternal() {
        let subject = InternalMetadata()
        XCTAssertEqual(subject.description, "md/internal")
    }
}
