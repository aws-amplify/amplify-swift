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

class GraphQLSubscriptionTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: Comment.self)
        ModelRegistry.register(modelType: Post.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    // MARK: - Subscriptions

    /// - Given: a `Model` type
    /// - When:
    ///   - the model has no eager loaded associations
    ///   - the subscription is of type `.onCreate`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid subscription
    ///     - it has a list of fields with no nested models
    func testOnCreateGraphQLSubscriptionFromSimpleModel() {
        let document = GraphQLSubscription(of: Post.self, type: .onCreate)
        let expectedQueryDocument = """
        subscription OnCreatePost {
          onCreatePost {
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
        XCTAssertEqual(document.name, "onCreatePost")
        XCTAssertEqual(document.decodePath, "onCreatePost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.variables.count, 0)

    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Comment`
    ///   - the model has required associations
    ///   - the subscription is of type `.onCreate`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid subscription
    ///     - it has a list of fields with no nested models
    func testOnCreateGraphQLSubscriptionFromModelWithAssociation() {
        let document = GraphQLSubscription(of: Comment.self, type: .onCreate)
        let expectedQueryDocument = """
        subscription OnCreateComment {
          onCreateComment {
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
        XCTAssertEqual(document.name, "onCreateComment")
        XCTAssertEqual(document.decodePath, "onCreateComment")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.variables.count, 0)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model has no eager loaded associations
    ///   - the subscription is of type `.onUpdate`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid subscription
    ///     - it has a list of fields with no nested models
    func testOnUpdateGraphQLSubscriptionFromSimpleModel() {
        let document = GraphQLSubscription(of: Post.self, type: .onUpdate)
        let expectedQueryDocument = """
        subscription OnUpdatePost {
          onUpdatePost {
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
        XCTAssertEqual(document.name, "onUpdatePost")
        XCTAssertEqual(document.decodePath, "onUpdatePost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.variables.count, 0)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model has no eager loaded associations
    ///   - the subscription is of type `.onDelete`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid subscription
    ///     - it has a list of fields with no nested models
    func testOnDeleteGraphQLSubscriptionFromSimpleModel() {
        let document = GraphQLSubscription(of: Post.self, type: .onDelete)
        let expectedQueryDocument = """
        subscription OnDeletePost {
          onDeletePost {
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
        XCTAssertEqual(document.name, "onDeletePost")
        XCTAssertEqual(document.decodePath, "onDeletePost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.variables.count, 0)
    }

}
