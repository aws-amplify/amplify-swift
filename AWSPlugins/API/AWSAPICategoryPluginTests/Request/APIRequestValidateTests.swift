//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSAPICategoryPlugin

class APIRequestValidateTests: XCTestCase {

    let testApiName = "testApiName"

    func testAPIRequestValidate() {
        let apiRequest = APIRequest(apiName: testApiName,
                                    operationType: .get,
                                    path: "",
                                    body: "",
                                    options: APIRequest.Options())

        let result = apiRequest.validate()

        XCTAssertNil(result)
    }
}
