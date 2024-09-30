//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSClientRuntime
import XCTest

class SDKMetadataTests: XCTestCase {

    func test_description_includesSanitizedVersion() {
        let subject = SDKMetadata(version: "4.5.6🤡")
        XCTAssertEqual(subject.description, "aws-sdk-swift/4.5.6-")
    }
}
