//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSAPIPlugin

class AppSyncListPayloadTests: XCTestCase {

    func testRetrieveFilterAndLimit() {
        let variables: [String: JSONValue] = [
            "filter": [
                "postID": [
                    "eq": "postId123"
                ]
            ],
            "limit": 500
        ]
        let payload = AppSyncListPayload(graphQLData: JSONValue.null,
                                         apiName: "apiName",
                                         variables: variables)

        guard let limit = payload.limit else {
            XCTFail("Could not get limit from payload")
            return
        }
        XCTAssertEqual(limit, 500)
        guard let filter = payload.graphQLFilter else {
            XCTFail("Could not get filter from payload")
            return
        }
        guard let postFilter = filter["postID"] as? [String: String],
              let postId = postFilter["eq"] else {
            XCTFail("Could not retrieve filter values")
            return
        }
        XCTAssertEqual(postId, "postId123")
    }

    func testRetrieveNilFilterAndLimit_MissingKeys() {
        let variables: [String: JSONValue] = [
            "missingFilter": [
                "postID": [
                    "eq": "postId123"
                ]
            ],
            "missingLimit": 500
        ]
        let payload = AppSyncListPayload(graphQLData: JSONValue.null,
                                         apiName: "apiName",
                                         variables: variables)

        XCTAssertNil(payload.graphQLFilter)
        XCTAssertNil(payload.limit)
    }

    func testRetrieveNilFilterAndLimit_MissingVariables() {
        let payload = AppSyncListPayload(graphQLData: JSONValue.null,
                                         apiName: "apiName",
                                         variables: nil)

        XCTAssertNil(payload.graphQLFilter)
        XCTAssertNil(payload.limit)
    }
}
