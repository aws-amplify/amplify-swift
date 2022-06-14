//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AmplifyTestCommon
@testable import Amplify
@testable import AWSAPIPlugin

class AppSyncListResponseTests: XCTestCase {

    override func setUp() async throws {
        ModelRegistry.register(modelType: Comment4.self)
        ModelRegistry.register(modelType: Post4.self)
    }

    override class func tearDown() {
        ModelRegistry.reset()
    }

    func testInitWithMetadata() throws {
        let graphQLData: JSONValue = [
            "items": [
                [
                    "id": "1",
                    "title": JSONValue.init(stringLiteral: "title"),
                    "__typename": "Post4"
                ], [
                    "id": "2",
                    "title": JSONValue.init(stringLiteral: "title"),
                    "__typename": "Post4"
                ]
            ],
            "nextToken": "nextToken"
        ]
        let listResponse = try AppSyncListResponse.initWithMetadata(type: Post4.self,
                                                                    graphQLData: graphQLData,
                                                                    apiName: "apiName")

        XCTAssertEqual(listResponse.items.count, 2)
        XCTAssertEqual(listResponse.nextToken, "nextToken")
    }

    func testMissingNextToken() throws {
        let graphQLData: JSONValue = [
            "items": [
                [
                    "id": "1",
                    "content": JSONValue.init(stringLiteral: "content"),
                    "__typename": "Comment4"
                ], [
                    "id": "2",
                    "content": JSONValue.init(stringLiteral: "content"),
                    "__typename": "Comment4"
                ]
            ]
        ]
        let listResponse = try AppSyncListResponse.initWithMetadata(type: Comment4.self,
                                                                graphQLData: graphQLData,
                                                                apiName: "apiName")

        XCTAssertEqual(listResponse.items.count, 2)
        XCTAssertNil(listResponse.nextToken)
    }

}
