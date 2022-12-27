//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import XCTest
import Amplify
@testable import AWSAPIPlugin

class GraphQLOperationRequestUtilsTests: XCTestCase {

    let baseURL = URL(string: "https://someurl")
    let testDocument = "testDocument"

    func testGraphQLOperationRequestWithCache() throws {
        let request = GraphQLOperationRequestUtils.constructRequest(with: baseURL,
                                                                    requestPayload: Data())
        XCTAssertEqual(request.allHTTPHeaderFields["Cache-Control"], "no-store")
    }
}
