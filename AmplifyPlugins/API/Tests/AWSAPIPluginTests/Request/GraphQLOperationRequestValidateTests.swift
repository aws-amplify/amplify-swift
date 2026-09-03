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
class GraphQLOperationRequestValidateTests: XCTestCase, @unchecked Sendable {

    let testApiName = "testApiName"
    let testDocument = "testDocument"

    func testGraphQLOperationRequestValidate() throws {
        let requestOptions = GraphQLOperationRequest<String>.Options(pluginOptions: nil)
        let graphQLOperationRequest = GraphQLOperationRequest(
            apiName: testApiName,
            operationType: .mutation,
            document: testDocument,
            responseType: String.self,
            options: requestOptions
        )
        XCTAssertNoThrow(try graphQLOperationRequest.validate())
    }
}
