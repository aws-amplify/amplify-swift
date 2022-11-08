//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore

class GraphQLSyncQueryTests: XCTestCase {

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
    ///   - the query is of type `.sync`
    /// - Then:
    ///   - check if the generated GraphQL document is valid query:
    ///     - - it contains an `filter` argument of type `ModelPostFilterInput`
    ///     - it is named `syncPosts`
    ///     - it has a list of fields with no nested models
    func testSyncGraphQLQueryForPost() {
        let post = Post.keys
        let predicate = post.id.eq("id") && (post.title.beginsWith("Title") || post.content.contains("content"))

        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .sync))
        documentBuilder.add(decorator: FilterDecorator(filter: predicate.graphQLFilter(for: Post.schema)))
        documentBuilder.add(decorator: PaginationDecorator(limit: 100, nextToken: "token"))
        documentBuilder.add(decorator: ConflictResolutionDecorator(lastSync: 123))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query SyncPosts($filter: ModelPostFilterInput, $lastSync: AWSTimestamp, $limit: Int, $nextToken: String) {
          syncPosts(filter: $filter, lastSync: $lastSync, limit: $limit, nextToken: $nextToken) {
            items {
              id
              content
              createdAt
              draft
              rating
              status
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
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.name, "syncPosts")
        XCTAssertNotNil(document.variables)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertNotNil(variables["limit"])
        XCTAssertEqual(variables["limit"] as? Int, 100)
        XCTAssertNotNil(variables["nextToken"])
        XCTAssertEqual(variables["nextToken"] as? String, "token")
        XCTAssertNotNil(variables["filter"])
        XCTAssertNotNil(variables["lastSync"])
        XCTAssertEqual(variables["lastSync"] as? Int, 123)
    }

    func testSyncGraphQLQueryForComment() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Comment.schema,
                                                               operationType: .query,
                                                               primaryKeysOnly: true)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .sync))
        documentBuilder.add(decorator: PaginationDecorator(limit: 100, nextToken: "token"))
        documentBuilder.add(decorator: ConflictResolutionDecorator(lastSync: 123))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        query SyncComments($lastSync: AWSTimestamp, $limit: Int, $nextToken: String) {
          syncComments(lastSync: $lastSync, limit: $limit, nextToken: $nextToken) {
            items {
              id
              content
              createdAt
              post {
                id
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
            nextToken
            startedAt
          }
        }
        """
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
    }
}
