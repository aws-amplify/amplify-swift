//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSAPIPlugin

class APIErrorUnauthorizedTests: XCTestCase {

    func testAPIErrorUnauthorized() throws {
        let apiError = APIError.operationError("Unauthorized", "", nil)

        XCTAssertTrue(apiError.isUnauthorized())
    }

    func testAPIErrorUnauthorizedLowerCase() throws {
        let apiError = APIError.operationError("unauthorized", "", nil)

        XCTAssertTrue(apiError.isUnauthorized())
    }

    func testAPIErrorHTTPStatus401() throws {
        let apiError = APIError.httpStatusError(401, .init())

        XCTAssertTrue(apiError.isUnauthorized())
    }

    func testAPIErrorHTTPStatus403() throws {
        let apiError = APIError.httpStatusError(403, .init())

        XCTAssertTrue(apiError.isUnauthorized())
    }
}
