//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import AWSCognitoAuthPlugin

class SignUpPasswordValidatorTests: XCTestCase {

    func testValidatingEmptyPassword() throws {
        XCTAssertEqual(validate(password: ""), .invalidPassword(message: ""))
    }

    func testValidatingTooLongPassword() throws {
        let tooLong = [String](repeating: "x", count: 260).joined(separator: "")
        XCTAssertEqual(validate(password: tooLong), .invalidPassword(message: ""))
    }

    func testValidatingPasswordWithWhitespace() throws {
        XCTAssertEqual(validate(password: "abc 123"), .invalidPassword(message: ""))
    }

    private func validate(password: String) -> SignUpError? {
        SignUpPasswordValidator.validate(password: password)
    }

}
