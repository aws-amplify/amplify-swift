//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSClientRuntime

class LanguageMetadataTests: XCTestCase {

    func testHappyPath() {
        let sut = LanguageMetadata(version: "5.0")
        XCTAssertEqual("lang/swift#5.0", sut.description)
    }

    func testHappyPathWithSingleExtra() {
        let additionalMetadata = [AdditionalMetadata(name: "test1", value: "4.3")]
        let sut = LanguageMetadata(version: "5.1", additionalMetadata: additionalMetadata)
        XCTAssertEqual("lang/swift#5.1 md/test1#4.3", sut.description)
    }

    func testHappyPathWithMultipleExtras() {
        let additionalMetadata = [AdditionalMetadata(name: "test1", value: "4.4"), AdditionalMetadata(name: "test2", value: "9.0.1")]
        let sut = LanguageMetadata(version: "5.2", additionalMetadata: additionalMetadata)
        let option1 = "lang/swift#5.2 md/test1#4.4 md/test2#9.0.1" == sut.description
        let option2 = "lang/swift#5.2 md/test2#9.0.1 md/test1#4.4" == sut.description
        XCTAssert(option1 || option2)
    }

    func testHappyPathWithMultipleExtrasSanitize() {
        let additionalMetadata = [AdditionalMetadata(name: "test🍺3", value: "4.1"), AdditionalMetadata(name: "test🍙4", value: "9.0.🍘2")]
        let sut = LanguageMetadata(version: "4👍.2", additionalMetadata: additionalMetadata)
        let option1 = "lang/swift#4-.2 md/test-3#4.1 md/test-4#9.0.-2" == sut.description
        let option2 = "lang/swift#4-.2 md/test-4#9.0.-2 md/test-3#4.1" == sut.description
        XCTAssert(option1 || option2)
    }
}
