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

class GraphQLListQueryTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: Comment.self)
        ModelRegistry.register(modelType: Post.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Post`
    ///   - the model has no eager loaded connections
    ///   - the query is of type `.list`
    /// - Then:
    ///   - check if the generated GraphQL document is valid query:
    ///     - it contains an `filter` argument of type `ModelPostFilterInput`
    ///     - it is named `listPosts`
    ///     - it has a list of fields with no nested models
    ///     - fields are wrapped with `items`
    func testListGraphQLQueryFromSimpleModel() {
        let post = Post.keys
        let predicate = post.id.eq("id") && (post.title.beginsWith("Title") || post.content.contains("content"))

        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .list))
        documentBuilder.add(decorator: PaginationDecorator())
        documentBuilder.add(decorator: FilterDecorator(filter: predicate.graphQLFilter))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query ListPosts($filter: ModelPostFilterInput, $limit: Int) {
          listPosts(filter: $filter, limit: $limit) {
            items {
              id
              content
              createdAt
              draft
              rating
              title
              updatedAt
              __typename
            }
            nextToken
          }
        }
        """
        XCTAssertEqual(document.name, "listPosts")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertNotNil(document.variables)
        XCTAssertNotNil(document.variables["limit"])
        XCTAssertEqual(document.variables["limit"] as? Int, 1_000)
        XCTAssertNotNil(document.variables["filter"])
    }

    func testListGraphQLQueryFromSimpleModelWithSyncEnabled() {
        let post = Post.keys
        let predicate = post.id.eq("id") && (post.title.beginsWith("Title") || post.content.contains("content"))

        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .list))
        documentBuilder.add(decorator: PaginationDecorator())
        documentBuilder.add(decorator: FilterDecorator(filter: predicate.graphQLFilter))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query ListPosts($filter: ModelPostFilterInput, $limit: Int) {
          listPosts(filter: $filter, limit: $limit) {
            items {
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
            nextToken
            startedAt
          }
        }
        """
        XCTAssertEqual(document.name, "listPosts")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertNotNil(document.variables)
        XCTAssertNotNil(document.variables["limit"])
        XCTAssertEqual(document.variables["limit"] as? Int, 1_000)
        XCTAssertNotNil(document.variables["filter"])
    }
}
