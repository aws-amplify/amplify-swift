//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest


import XCTest
import Amplify
@testable import AWSAPICategoryPlugin

class GraphQLRequestValidateTests: XCTestCase {

    let testApiName = "testApiName"
    let testDocument = "testDocument"

    func testRESTRequestValidate() {
        let graphQLRequest = GraphQLRequest(apiName: testApiName,
                                            operationType: .mutation,
                                            document: testDocument,
                                            options: GraphQLRequest.Options())
        let result = graphQLRequest.validate()

        XCTAssertNil(result)
    }
}
