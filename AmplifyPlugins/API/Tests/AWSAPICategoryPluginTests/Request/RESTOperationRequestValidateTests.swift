//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSAPIPlugin

class RESTOperationRequestValidateTests: XCTestCase {

    let testApiName = "testApiName"

    func testRESTOperationRequestValidate() {
        let restOperationRequest = RESTOperationRequest(apiName: testApiName,
                                                        operationType: .get,
                                                        options: RESTOperationRequest.Options())

        XCTAssertNoThrow(try restOperationRequest.validate())
    }
}
