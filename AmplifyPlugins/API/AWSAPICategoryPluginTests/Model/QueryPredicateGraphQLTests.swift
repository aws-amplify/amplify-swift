//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPlugin

class QueryPredicateGraphQLTests: XCTestCase {

    func testPredicateToGraphQLValues() throws {
        let post = Post.keys
        guard let date = "2019-11-23T02:06:50.689Z".iso8601 else {
            XCTFail("Failed to set up date")
            return
        }
        let predicate = post.id == "id" && post.createdAt == date && post.draft != true && post.rating == 12.3
        let expected = """
        {
          "and" : [
            {
              "id" : {
                "eq" : "id"
              }
            },
            {
              "createdAt" : {
                "eq" : "2019-11-23T02:06:50.689Z"
              }
            },
            {
              "draft" : {
                "ne" : true
              }
            },
            {
              "rating" : {
                "eq" : 12.3
              }
            }
          ]
        }
        """
        let result = try predicate.graphQLFilterVariablesString()
        XCTAssertEqual(result, expected)
    }

    func testPredicateToGraphQLOperators() throws {
        let post = Post.keys
        let id = "id"
        let predicate = post.id != id &&
            post.id == id &&
            post.id < id &&
            post.id <= id &&
            post.id > id &&
            post.id >= id &&
            post.id.contains(id) &&
            post.id.between(start: id, end: id) &&
            post.id.beginsWith(id)
        let expected = """
        {
          "and" : [
            {
              "id" : {
                "ne" : "id"
              }
            },
            {
              "id" : {
                "eq" : "id"
              }
            },
            {
              "id" : {
                "lt" : "id"
              }
            },
            {
              "id" : {
                "le" : "id"
              }
            },
            {
              "id" : {
                "gt" : "id"
              }
            },
            {
              "id" : {
                "ge" : "id"
              }
            },
            {
              "id" : {
                "contains" : "id"
              }
            },
            {
              "id" : {
                "between" : [
                  "id",
                  "id"
                ]
              }
            },
            {
              "id" : {
                "beginsWith" : "id"
              }
            }
          ]
        }
        """
        let result = try predicate.graphQLFilterVariablesString()
        XCTAssertEqual(result, expected)
    }

    func testPredicateWithNestedOperator() throws {
        let post = Post.keys
        let predicate = post.id.eq("id") && (post.title.beginsWith("Title") || post.content.contains("content"))
        let expected = """
        {
          "and" : [
            {
              "id" : {
                "eq" : "id"
              }
            },
            {
              "or" : [
                {
                  "title" : {
                    "beginsWith" : "Title"
                  }
                },
                {
                  "content" : {
                    "contains" : "content"
                  }
                }
              ]
            }
          ]
        }
        """
        let result = try predicate.graphQLFilterVariablesString()
        XCTAssertEqual(result, expected)
    }
}
