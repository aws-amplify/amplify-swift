//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSAPICategoryPlugin

class RESTRequestValidateTests: XCTestCase {

    let testApiName = "testApiName"

    func testRESTRequestValidate() {
        let request = RESTRequest(apiName: testApiName,
                                    operationType: .get,
                                    path: "",
                                    body: Data(),
                                    options: RESTRequest.Options())

        let result = request.validate()

        XCTAssertNil(result)
    }
}
