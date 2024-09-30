//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSClientRuntime
import XCTest

class UserAgentMetadataTests: XCTestCase {

    func test_description_isAsExpected() {
        let subject = UserAgentMetadata()
        XCTAssertEqual(subject.description, "ua/2.1")
    }
}
