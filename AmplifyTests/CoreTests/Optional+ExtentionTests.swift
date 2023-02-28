//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
		
@_spi(OptionalExtension) import Amplify
import XCTest

class OptionalExtensionTests: XCTestCase {

    /// - Given:
    ///     Optional of integer with none
    /// - When:
    ///     apply a function to increase a captured local integer variable with value 0
    /// - Then:
    ///     - the peek function on optional should not be applied
    ///     - local integer variable value stays 0
    ///     - the optional stay unchanged
    func testPeek_withNone_doNothing() {
        var sideEffect = 0
        let optional: Int? = .none
        let afterPeek = optional.peek { _ in sideEffect += 1 }
        XCTAssertEqual(0, sideEffect)
        XCTAssertEqual(afterPeek, optional)
    }

    /// - Given:
    ///     Optional of integer with value 10
    /// - When:
    ///     apply a function to increase a captured local integer variable with value 0
    /// - Then:
    ///     - the peek function on optioanl should be applied
    ///     - capture local integer value equals 1
    ///     - the optional stay unchanged
    func testPeek_withValue_applyFunction() {
        var sideEffect = 0
        let optional: Int? = .some(10)
        let afterPeek = optional.peek { _ in sideEffect += 1 }
        XCTAssertEqual(1, sideEffect)
        XCTAssertEqual(afterPeek, optional)
    }

}
