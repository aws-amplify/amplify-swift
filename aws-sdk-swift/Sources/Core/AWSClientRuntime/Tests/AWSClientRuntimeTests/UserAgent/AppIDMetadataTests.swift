//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSClientRuntime
import XCTest

class AppIDMetadataTests: XCTestCase {

    func test_description_sanitizesTheAppID() throws {
        let subject = try XCTUnwrap(AppIDMetadata(name: "Self Driving 🤡 Car"))
        XCTAssertEqual(subject.description, "app/Self-Driving---Car")
    }
}
