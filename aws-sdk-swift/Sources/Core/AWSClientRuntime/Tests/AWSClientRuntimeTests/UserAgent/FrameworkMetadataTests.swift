//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSClientRuntime

class FrameworkMetadataTests: XCTestCase {

    func testWithNoMetadata() {
        let sut = FrameworkMetadata(name: "aws-amplify", version: "2.0.0")
        XCTAssertEqual("lib/aws-amplify#2.0.0", sut.description)
    }

    func testNameIsSanitized() {
        let sut = FrameworkMetadata(name: "aws-🐶woof", version: "1.2🐈.3")
        XCTAssertEqual("lib/aws--woof#1.2-.3", sut.description)
    }

    func testWithSingleMetadata() {
        let additionalMetadata = [AdditionalMetadata(name: "test", value: "1.0")]
        let sut = FrameworkMetadata(name: "aws-amplify", version: "2.0.0", additionalMetadata: additionalMetadata)
        XCTAssertEqual("lib/aws-amplify#2.0.0 md/test#1.0", sut.description)
    }

    func testWithMultipleMetadata() {
        let additionalMetadata = [AdditionalMetadata(name: "test1", value: "1.0"), AdditionalMetadata(name: "test2", value: "SomethingOtherThanANumber")]
        let sut = FrameworkMetadata(name: "aws-amplify", version: "2.0.0", additionalMetadata: additionalMetadata)
        let option1 = "lib/aws-amplify#2.0.0 md/test1#1.0 md/test2#SomethingOtherThanANumber" == sut.description
        let option2 = "lib/aws-amplify#2.0.0 md/test2#SomethingOtherThanANumber md/test1#1.0" == sut.description
        XCTAssert(option1 || option2)
    }

    func testMetadataIsSanitized() {
        let additionalMetadata = [AdditionalMetadata(name: "tes🍷t3", value: "1.2.🙉🙈🙊7")]
        let sut = FrameworkMetadata(name: "aws-nextProduct", version: "2.0.0", additionalMetadata: additionalMetadata)
        XCTAssertEqual("lib/aws-nextProduct#2.0.0 md/tes-t3#1.2.---7", sut.description)
    }
}
