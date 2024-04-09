//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
@testable @_spi(AmplifyAPI) import AWSAPIPlugin

class ArrayWithErrorElementExtensionTests: XCTestCase {



    func testCast_toCorrectErrorType_returnCastedErrorType() {
        let errors: [Error] = [
            Error1(), Error1(), Error1()
        ]

        let error1s = errors.cast(to: Error1.self)
        XCTAssertNotNil(error1s)
        XCTAssertTrue(!error1s!.isEmpty)
        XCTAssertEqual(errors.count, error1s!.count)
    }

    func testCast_toWrongErrorType_returnNil() {
        let errors: [Error] = [
            Error1(), Error1(), Error1()
        ]

        let error2s = errors.cast(to: Error2.self)
        XCTAssertNil(error2s)
    }

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
