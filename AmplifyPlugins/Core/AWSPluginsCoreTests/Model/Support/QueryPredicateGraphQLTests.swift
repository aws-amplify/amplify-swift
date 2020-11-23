//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore

class QueryPredicateGraphQLTests: XCTestCase {

    func testPredicateToGraphQLValues() throws {
        let post = Post.keys
        guard let date = try? Temporal.DateTime(iso8601String: "2019-11-23T02:06:50.689Z") else {
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
        let result = try GraphQLFilterConverter.toJSON(predicate, options: [.prettyPrinted])
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
        let result = try GraphQLFilterConverter.toJSON(predicate, options: [.prettyPrinted])
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
        let result = try GraphQLFilterConverter.toJSON(predicate, options: [.prettyPrinted])
        XCTAssertEqual(result, expected)
    }

    func testPredicateWithNestedAndOperator() throws {
        let post = Post.keys
        let predicate = (post.title.beginsWith("Title") && post.content.contains("content")) || post.id.eq("id")
        let expected = """
        {
          "or" : [
            {
              "and" : [
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
            },
            {
              "id" : {
                "eq" : "id"
              }
            }
          ]
        }
        """
        let result = try GraphQLFilterConverter.toJSON(predicate, options: [.prettyPrinted])
        XCTAssertEqual(result, expected)
    }

    func testPredicateWithNestedOrOperator() throws {
        let post = Post.keys
        let predicate = (post.title.beginsWith("Title") || post.content.contains("content")) && post.id.eq("id")
        let expected = """
        {
          "and" : [
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
            },
            {
              "id" : {
                "eq" : "id"
              }
            }
          ]
        }
        """
        let result = try GraphQLFilterConverter.toJSON(predicate, options: [.prettyPrinted])
        XCTAssertEqual(result, expected)
    }

    func testJSONSerializationAndDeserialization() throws {
        let post = Post.keys
        let predicate = post.id.eq("id") && post.title.beginsWith("Title")
        let result = try GraphQLFilterConverter.toJSON(predicate)
        XCTAssertNotNil(result)
        let graphQLFilter = try GraphQLFilterConverter.fromJSON(result)
        guard let filter = graphQLFilter["and"] as? [[String: Any]] else {
            XCTFail("should contain 'and' operation")
            return
        }
        let idPredicate = filter[0]
        guard let idFilter = idPredicate["id"] as? [String: Any] else {
            XCTFail("should contain 'id' value")
            return
        }
        XCTAssert(idFilter["eq"] as? String == "id")

        let titlePredicate = filter[1]
        guard let titleFilter = titlePredicate["title"] as? [String: Any] else {
            XCTFail("should contain 'title' value")
            return
        }

        XCTAssert(titleFilter["beginsWith"] as? String == "Title")
    }

    func testSupportedPredicateSupportsDate() throws {
        let date = try Temporal.Date(iso8601String: "2019-11-23")
        XCTAssertNotNil(Post.keys.createdAt == date)
    }

    func testSupportedPredicateSupportsDateTime() throws {
        let dateTime = try Temporal.DateTime(iso8601String: "2019-11-23T02:06:50.689Z")
        XCTAssertNotNil(Post.keys.createdAt == dateTime)
    }

    func testSupportedPredicateSupportsTime() throws {
        let time = try Temporal.Time(iso8601String: "02:06:50.689")
        XCTAssertNotNil(Post.keys.createdAt == time)
    }

}
