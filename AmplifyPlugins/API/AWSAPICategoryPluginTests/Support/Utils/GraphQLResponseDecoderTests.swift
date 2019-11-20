//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSAPICategoryPlugin

class GraphQLResponseDecoderTests: XCTestCase {

    /// Test decode of a raw data operation
    ///
    /// - Given: The bytes of a GraphQL response
    /// - When:
    ///    - I invoke `decode`
    /// - Then:
    ///    - I get the expected result type
    ///
    func testDecode() throws {
        let jsonDictionary: [String: JSONValue] = [
            "foo": "bar"
        ]

        let response = AWSAppSyncGraphQLResponse(data: jsonDictionary, errors: nil)
        let decodedResponse = try GraphQLResponseDecoder.decode(graphQLServiceResponse: response,
                                                                responseType: JSONValue.self,
                                                                decodePath: nil,
                                                                rawGraphQLResponse: Data())

        XCTAssertNotNil(decodedResponse)
//        XCTAssertEqual(decodedResponse["foo"], "bar")
    }

}
