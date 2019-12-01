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

class GraphQLGetQueryTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: Comment.self)
        ModelRegistry.register(modelType: Post.self)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Post`
    ///   - the model has no eager loaded connections
    ///   - the query is of type `.get`
    /// - Then:
    ///   - check if the generated GraphQL document is valid query:
    ///     - it contains an `id` argument of type `ID!`
    ///     - it is named `getPost`
    ///     - it has a list of fields with no nested models
    ///     - it has variables containing `id`
    func testGetGraphQLQueryFromSimpleModel() {
        let document = GraphQLGetQuery(from: Post.self, id: "id")
        let expectedQueryDocument = """
        query GetPost($id: ID!) {
          getPost(id: $id) {
            id
            content
            createdAt
            draft
            rating
            title
            updatedAt
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        XCTAssertEqual(document.name, "getPost")
        XCTAssertEqual(document.decodePath, "getPost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.variables["id"] as? String, "id")
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Comment`
    ///   - the model has eager loaded associations
    ///   - the query is of type `.get`
    /// - Then:
    ///   - check if the generated GraphQL document is valid query:
    ///     - it contains an `id` argument of type `ID!`
    ///     - it is named `getComment`
    ///     - it has a list of fields with a nested `post`
    func testGetGraphQLQueryFromModelWithAssociation() {
        let document = GraphQLGetQuery(from: Comment.self, id: "id")
        let expectedQueryDocument = """
        query GetComment($id: ID!) {
          getComment(id: $id) {
            id
            content
            createdAt
            post {
              id
              content
              createdAt
              draft
              rating
              title
              updatedAt
              __typename
              _version
              _deleted
              _lastChangedAt
            }
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        XCTAssertEqual(document.name, "getComment")
        XCTAssertEqual(document.decodePath, "getComment")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.variables["id"] as? String, "id")
    }

}
