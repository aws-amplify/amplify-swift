//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AmplifyTestCommon
import AWSPluginsCore
@testable import Amplify
@testable import AWSAPIPlugin

class GraphQLRequestToListQueryTests: XCTestCase {

    override func setUp() async throws {
        ModelRegistry.register(modelType: Comment4.self)
        ModelRegistry.register(modelType: Post4.self)
    }

    override class func tearDown() {
        ModelRegistry.reset()
    }

    func testFirstPageRequestRequest() {
        let predicate = Comment4.keys.post == "postId123"
        let request = GraphQLRequest<JSONValue>.listQuery(responseType: JSONValue.self,
                                                          modelSchema: Comment4.schema,
                                                          filter: predicate.graphQLFilter(for: Comment4.schema),
                                                          limit: 1_000,
                                                          apiName: "apiName")
        XCTAssertNotNil(request)
        let expectedDocument = """
        query ListComment4s($filter: ModelComment4FilterInput, $limit: Int) {
          listComment4s(filter: $filter, limit: $limit) {
            items {
              id
              content
              post {
                id
                title
                __typename
              }
              __typename
            }
            nextToken
          }
        }
        """
        XCTAssertEqual(request.document, expectedDocument)
        XCTAssertEqual(request.decodePath, "listComment4s")
        XCTAssertEqual(request.apiName, "apiName")
        guard let variables = request.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertNotNil(variables["limit"])
        XCTAssertEqual(variables["limit"] as? Int, 1_000)
        guard let filter = variables["filter"] as? GraphQLFilter,
              let filterJSON = try? JSONSerialization.data(withJSONObject: filter,
                                                           options: .prettyPrinted) else {
            XCTFail("variables should contain a valid filter JSON")
            return
        }
        let expectedFilterJSON = """
        {
          "postID" : {
            "eq" : "postId123"
          }
        }
        """
        XCTAssertEqual(String(data: filterJSON, encoding: .utf8), expectedFilterJSON)
    }

    func testMextPageRequest() {
        let request = GraphQLRequest<JSONValue>.listQuery(responseType: List<Comment4>.self,
                                                          modelSchema: Comment4.schema,
                                                          nextToken: "nextToken",
                                                          apiName: "apiName")
        XCTAssertNotNil(request)
        let expectedDocument = """
        query ListComment4s($limit: Int, $nextToken: String) {
          listComment4s(limit: $limit, nextToken: $nextToken) {
            items {
              id
              content
              post {
                id
                title
                __typename
              }
              __typename
            }
            nextToken
          }
        }
        """
        XCTAssertEqual(request.document, expectedDocument)
        XCTAssertEqual(request.decodePath, "listComment4s")
        XCTAssertEqual(request.apiName, "apiName")
        guard let variables = request.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertNotNil(variables["limit"])
        XCTAssertEqual(variables["limit"] as? Int, 1_000)
        XCTAssertNotNil(variables["nextToken"])
        XCTAssertEqual(variables["nextToken"] as? String, "nextToken")
    }

    func testNextPageRequestWithLimitAndFilter() {
        let previousFilter: [String: Any] = [
            "postID": [
                "eq": "postId123"
            ]
        ]
        let request = GraphQLRequest<JSONValue>.listQuery(responseType: List<Comment4>.self,
                                                          modelSchema: Comment4.schema,
                                                          filter: previousFilter,
                                                          limit: 1_000,
                                                          nextToken: "nextToken",
                                                          apiName: "apiName")
        XCTAssertNotNil(request)
        let expectedDocument = """
        query ListComment4s($filter: ModelComment4FilterInput, $limit: Int, $nextToken: String) {
          listComment4s(filter: $filter, limit: $limit, nextToken: $nextToken) {
            items {
              id
              content
              post {
                id
                title
                __typename
              }
              __typename
            }
            nextToken
          }
        }
        """
        XCTAssertEqual(request.document, expectedDocument)
        XCTAssertEqual(request.decodePath, "listComment4s")
        XCTAssertEqual(request.apiName, "apiName")
        guard let variables = request.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertNotNil(variables["limit"])
        XCTAssertEqual(variables["limit"] as? Int, 1_000)
        XCTAssertNotNil(variables["nextToken"])
        XCTAssertEqual(variables["nextToken"] as? String, "nextToken")
        guard let filter = variables["filter"] as? GraphQLFilter,
              JSONSerialization.isValidJSONObject(filter),
              let filterJSON = try? JSONSerialization.data(withJSONObject: filter,
                                                           options: .prettyPrinted) else {
            XCTFail("variables should contain a valid filter JSON")
            return
        }
        let expectedFilterJSON = """
        {
          "postID" : {
            "eq" : "postId123"
          }
        }
        """
        XCTAssertEqual(String(data: filterJSON, encoding: .utf8), expectedFilterJSON)
    }

}
