//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest
@testable import AWSAPIPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class RESTOperationRequestValidateTests: XCTestCase, @unchecked Sendable {

    let testApiName = "testApiName"

    func testRESTOperationRequestValidate() {
        let restOperationRequest = RESTOperationRequest(
            apiName: testApiName,
            operationType: .get,
            options: RESTOperationRequest.Options()
        )

        XCTAssertNoThrow(try restOperationRequest.validate())
    }
}
