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
class GraphQLOperationRequestUtilsTests: XCTestCase, @unchecked Sendable {

    let baseURL = URL(string: "https://someurl")!
    let testDocument = "testDocument"

    func testGraphQLOperationRequestWithCache() throws {
        let request = GraphQLOperationRequestUtils.constructRequest(
            with: baseURL,
            requestPayload: Data()
        )
        XCTAssertEqual(request.allHTTPHeaderFields?["Cache-Control"], "no-store")
    }
}
