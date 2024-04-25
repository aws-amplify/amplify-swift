//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
@testable @_spi(AmplifyAPI) import AWSAPIPlugin

class ArrayWithErrorElementExtensionTests: XCTestCase {

    /**
     Given: errors with generic protocol type
     When: cast to the correct underlying concrete type
     Then: successfully casted to underlying concrete type
     */
    func testCast_toCorrectErrorType_returnCastedErrorType() {
        let errors: [Error] = [
            Error1(), Error1(), Error1()
        ]

        let error1s = errors.cast(to: Error1.self)
        XCTAssertNotNil(error1s)
        XCTAssertTrue(!error1s!.isEmpty)
        XCTAssertEqual(errors.count, error1s!.count)
    }

    /**
     Given: errors with generic protocol type
     When: cast to the wong underlying concrete type
     Then: return nil
     */
    func testCast_toWrongErrorType_returnNil() {
        let errors: [Error] = [
            Error1(), Error1(), Error1()
        ]

        let error2s = errors.cast(to: Error2.self)
        XCTAssertNil(error2s)
    }

    /**
     Given: errors with generic protocol type
     When: some of the elements failed to cast to the underlying concrete type
     Then: return nil
     */

    func testCast_partiallyToWrongErrorType_returnNil() {
        let errors: [Error] = [
            Error2(), Error2(), Error1()
        ]

        let error2s = errors.cast(to: Error2.self)
        XCTAssertNil(error2s)
    }

    struct Error1: Error { }

    struct Error2: Error { }
}
