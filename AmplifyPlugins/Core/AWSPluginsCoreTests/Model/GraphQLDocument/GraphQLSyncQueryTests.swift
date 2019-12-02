//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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
    func testSyncGraphQLQueryFromSimpleModel() {
        let post = Post.keys
        let predicate = post.id.eq("id") && (post.title.beginsWith("Title") || post.content.contains("content"))
        let document = GraphQLSyncQuery(from: Post.self,
                                        predicate: predicate,
                                        limit: 100,
                                        nextToken: "token",
                                        lastSync: 123)
        let expectedQueryDocument = """
        query SyncPosts($filter: ModelPostFilterInput, $limit: Int, $nextToken: String, $lastSync: AWSTimestamp) {
          syncPosts(filter: $filter, limit: $limit, nextToken: $nextToken, lastSync: $lastSync) {
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
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.decodePath, "syncPosts")
        XCTAssertNotNil(document.variables)
        XCTAssertNotNil(document.variables["limit"])
        XCTAssertEqual(document.variables["limit"] as? Int, 100)
        XCTAssertNotNil(document.variables["nextToken"])
        XCTAssertEqual(document.variables["nextToken"] as? String, "token")
        XCTAssertNotNil(document.variables["filter"])
        XCTAssertNotNil(document.variables["lastSync"])
        XCTAssertEqual(document.variables["lastSync"] as? Int, 123)
    }

}
