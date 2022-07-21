//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSAPIPlugin

class GraphQLErrorDecoderTests: XCTestCase {

    func testDecodeErrors() throws {
        let graphQLErrorJSON: JSONValue = [
            "message": "Name for character with ID 1002 could not be fetched.",
            "locations": [["line": 6, "column": 7]],
            "path": ["hero", "heroFriends", 1, "name"]
        ]
        let graphQLErrorJSON2: JSONValue = [
            "message": "Name for character with ID 1002 could not be fetched.",
            "locations": [["line": 6, "column": 7]],
            "path": ["hero", "heroFriends", 1, "name"],
            "extensions": [
                "code": "CAN_NOT_FETCH_BY_ID",
                "timestamp": "Fri Feb 9 14:33:09 UTC 2018"
            ]
        ]

        let graphQLErrors = try GraphQLErrorDecoder
            .decodeErrors(graphQLErrors: [graphQLErrorJSON, graphQLErrorJSON2])

        XCTAssertEqual(graphQLErrors.count, 2)
        let result = graphQLErrors[0]
        XCTAssertEqual(result.message, "Name for character with ID 1002 could not be fetched.")
        XCTAssertNotNil(result.locations)
        XCTAssertNotNil(result.path)
        XCTAssertNil(result.extensions)

        let result2 = graphQLErrors[1]
        XCTAssertEqual(result2.message, "Name for character with ID 1002 could not be fetched.")
        XCTAssertNotNil(result2.locations)
        XCTAssertNotNil(result2.path)
        XCTAssertNotNil(result2.extensions)
    }

    /// Decoding the graphQL error into `GraphQLError` will merge fields which do not meet the GraphQL spec for error
    /// fields ("message", "locations", "path", and "extensions") will be merged into extensions, without overwriting
    /// what is currently there
    ///
    /// - Given: GraphQL error JSON with extra fields ("errorInfo", "data", "errorType", "code"). "code" is duplicated
    ///          in extensions.
    /// - When:
    ///    - Decode into `GraphQLError`
    /// - Then:
    ///    - Extra fields are merged under `GraphQLError.extensions` without overwriting data, such as the "code" field
    func testDecodeErrorWithExtensions() throws {
        let graphQLErrorJSON: JSONValue = [
            "message": "Name for character with ID 1002 could not be fetched.",
            "locations": [["line": 6, "column": 7]],
            "path": ["hero", "heroFriends", 1, "name"],
            "extensions": [
                "code": "CAN_NOT_FETCH_BY_ID",
                "timestamp": "Fri Feb 9 14:33:09 UTC 2018"
            ],
            "errorInfo": nil,
            "data": [
              "id": "EF48518C-92EB-4F7A-A64E-D1B9325205CF",
              "title": "new3",
              "content": "Original content from DataStoreEndToEndTests at 2020-03-26 21:55:47 +0000",
              "_version": 2
            ],
            "errorType": "ConflictUnhandled",
            "code": 123
        ]
        let graphQLErrors = try GraphQLErrorDecoder.decodeErrors(graphQLErrors: [graphQLErrorJSON])

        XCTAssertEqual(graphQLErrors.count, 1)
        let result = graphQLErrors[0]
        XCTAssertEqual(result.message, "Name for character with ID 1002 could not be fetched.")
        XCTAssertNotNil(result.locations)
        XCTAssertNotNil(result.path)
        guard let extensions = result.extensions else {
            XCTFail("Missing extensions in result")
            return
        }
        XCTAssertEqual(extensions.count, 5)
        guard case let .string(code) = extensions["code"] else {
            XCTFail("Missing code")
            return
        }
        XCTAssertEqual(code, "CAN_NOT_FETCH_BY_ID")
        guard case let .string(timeStamp) = extensions["timestamp"] else {
            XCTFail("Missing timeStamp")
            return
        }
        XCTAssertEqual(timeStamp, "Fri Feb 9 14:33:09 UTC 2018")
        guard case .null = extensions["errorInfo"] else {
            XCTFail("Missing errorInfo")
            return
        }
        guard case let .object(data) = extensions["data"] else {
            XCTFail("Missing data")
            return
        }
        XCTAssertEqual(data["id"], "EF48518C-92EB-4F7A-A64E-D1B9325205CF")
        XCTAssertEqual(data["title"], "new3")
        XCTAssertEqual(data["content"],
                       "Original content from DataStoreEndToEndTests at 2020-03-26 21:55:47 +0000")
        XCTAssertEqual(data["_version"], 2)

        guard case let .string(errorType) = extensions["errorType"] else {
            XCTFail("Missing errorType")
            return
        }

        XCTAssertEqual(errorType, "ConflictUnhandled")
    }
}
