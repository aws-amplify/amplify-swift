//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSPluginsCore
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPlugin

class AppSyncListGraphQLRequestTests: XCTestCase {

    override func setUp() {
        Amplify.reset()
        ModelRegistry.register(modelType: Post4.self)
        ModelRegistry.register(modelType: Comment4.self)
    }

    func testAppSyncListRequestForFirstPage() {
        guard let commentSchema = ModelRegistry.modelSchema(from: "Comment4") else {
            XCTFail("Fail")
            return
        }
        guard let postModelField = commentSchema.field(withName: Comment4.keys.post.rawValue) else {
            XCTFail("Fail")
            return
        }
        let request = AppSyncList<Comment4>.requestForFirstPage(associatedId: "postId123",
                                                                associatedField: postModelField)
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

    func testAppSyncListRequestForNextPage() {
        let request = AppSyncList<Comment4>.requestForNextPage(nextToken: "nextToken", variables: nil)
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
        guard let variables = request.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertNotNil(variables["limit"])
        XCTAssertEqual(variables["limit"] as? Int, 1_000)
        XCTAssertNotNil(variables["nextToken"])
        XCTAssertEqual(variables["nextToken"] as? String, "nextToken")
    }

    func testAppSyncListRequestForNextPageWithSameLimitAndFilter() {
        let previousVariables: [String: JSONValue] = [
            "limit": 1_000,
            "filter": [
                "and": [
                    "postID": [
                        "eq": "postId123"
                    ],
                    "content": [
                        "beginWith": "hello"
                    ]
                ]
            ]
        ]
        let request = AppSyncList<Comment4>.requestForNextPage(nextToken: "nextToken", variables: previousVariables)
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
        guard let variables = request.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertNotNil(variables["limit"])
        XCTAssertEqual(variables["limit"] as? Int, 1_000)
        XCTAssertNotNil(variables["nextToken"])
        XCTAssertEqual(variables["nextToken"] as? String, "nextToken")
        guard let filter = variables["filter"] as? GraphQLFilter,
              let filterJSON = try? JSONSerialization.data(withJSONObject: filter,
                                                                 options: .prettyPrinted) else {
            XCTFail("variables should contain a valid filter JSON")
            return
        }
        let expectedFilterJSON = """
        {
          "and" : {
            "content" : {
              "beginWith" : "hello"
            },
            "postID" : {
              "eq" : "postId123"
            }
          }
        }
        """
        XCTAssertEqual(String(data: filterJSON, encoding: .utf8), expectedFilterJSON)
    }

}
