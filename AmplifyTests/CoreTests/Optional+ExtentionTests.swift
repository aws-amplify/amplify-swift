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
    ///     - the ifSome function on optional should not be applied
    ///     - local integer variable value stays 0
    func testIfSome_withNone_doNothing() {
        var sideEffect = 0
        let optional: Int? = .none
        optional.ifSome { _ in sideEffect += 1 }
        XCTAssertEqual(0, sideEffect)
    }

    /// - Given:
    ///     Optional of integer with value 10
    /// - When:
    ///     apply a function to increase a captured local integer variable with value 0
    /// - Then:
    ///     - the ifSome function on optioanl should be applied
    ///     - capture local integer value equals 1
    func testIfSome_withValue_applyFunction() {
        var sideEffect = 0
        let optional: Int? = .some(10)
        optional.ifSome { _ in sideEffect += 1 }
        XCTAssertEqual(1, sideEffect)
    }

    /// - Given:
    ///     Optional of integer with value 10
    /// - When:
    ///     apply a function that throw error
    /// - Then:
    ///     - the ifSome function on optioanl should be applied
    ///     - the error is rethrowed
    func testIfSome_withValue_applyFunctionRethrowError() {
        let optional: Int? = .some(10)
        let expectedError = TestRuntimeError()
        XCTAssertThrowsError(try optional.ifSome {_ in
            throw expectedError
        }) { error in
            XCTAssertEqual(expectedError, error as? TestRuntimeError)
        }
    }

}

fileprivate struct TestRuntimeError: Error, Equatable {
    let id = UUID()
}
