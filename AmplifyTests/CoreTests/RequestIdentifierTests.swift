//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class RequestIdentiferTests: XCTestCase {

    func testLongOperationRequest() {
        let request = LongOperationRequest(options: [:], steps: 10, delay: 0.25)
        XCTAssertFalse(request.requestID.isEmpty)
    }

}

