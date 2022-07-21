//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AmplifyTestCommon
@testable import AWSAPIPlugin

class ListTests: XCTestCase {

    override class func setUp() {
        ModelListDecoderRegistry.registerDecoder(AppSyncListDecoder.self)
    }

    func testDecodeToResponseTypeList() throws {
        let request = GraphQLRequest<List<Comment4>>(document: "",
                                                     responseType: List<Comment4>.self,
                                                     decodePath: "listComments")
        let decoder = GraphQLResponseDecoder(request: request.toOperationRequest(operationType: .query))
        let graphQLData: [String: JSONValue] = [
            "listComments": [
                "items": [
                    [
                        "id": "id",
                        "content": "content"
                    ],
                    [
                        "id": "id",
                        "content": " content"
                    ]
                ]
            ]
        ]

        let result = try decoder.decodeToResponseType(graphQLData)
        XCTAssertEqual(result.count, 2)
    }
}
