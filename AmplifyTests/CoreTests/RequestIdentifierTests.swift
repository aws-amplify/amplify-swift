//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class RequestIdentiferTests: XCTestCase, @unchecked Sendable {

    func testLongOperationRequest() {
        let request = LongOperationRequest(steps: 10, delay: 0.25)
        XCTAssertFalse(request.requestID.isEmpty)
    }

}

