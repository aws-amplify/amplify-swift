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

class GraphQLDocumentTests: XCTestCase {

    private let models: [Model.Type] = [Post.self, Comment.self]

    override func setUp() {
        models.forEach(registerModel(type:))
    }

    // MARK: - Mutations

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Post`
    ///   - the model has no eager loaded connections
    ///   - the mutation is of type `.create`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid mutation:
    ///     - it is named `createPost`
    ///     - it contains an `input` of type `CreatePostInput`
    ///     - it has a list of fields with no nested/connected models
    func testCreateGraphQLMutationFromSimpleModel() {
        let document = GraphQLMutation(of: Post.self, type: .create)
        let expected = """
        mutation CreatePost($input: CreatePostInput!) {
          createPost(input: $input) {
            id
            content
            createdAt
            draft
            rating
            title
            updatedAt
          }
        }
        """
        XCTAssertEqual(document.stringValue, expected)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Post`
    ///   - the model has no eager loaded connections
    ///   - the mutation is of type `.update`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid mutation:
    ///     - it is named `updatePost`
    ///     - it contains an `input` of type `UpdatePostInput`
    ///     - it has a list of fields with no nested/connected models
    func testUpdateGraphQLMutationFromSimpleModel() {
        let document = GraphQLMutation(of: Post.self, type: .update)
        let expected = """
        mutation UpdatePost($input: UpdatePostInput!) {
          updatePost(input: $input) {
            id
            content
            createdAt
            draft
            rating
            title
            updatedAt
          }
        }
        """
        XCTAssertEqual(document.stringValue, expected)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Post`
    ///   - the model has no eager loaded connections
    ///   - the mutation is of type `.delete`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid mutation:
    ///     - it is named `deletePost`
    ///     - it contains an `input` of type `ID!`
    ///     - it has a list of fields with no nested/connected models
    func testDeleteGraphQLMutationFromSimpleModel() {
        let document = GraphQLMutation(of: Post.self, type: .delete)
        let expected = """
        mutation DeletePost($id: ID!) {
          deletePost(id: $id) {
            id
            content
            createdAt
            draft
            rating
            title
            updatedAt
          }
        }
        """
        XCTAssertEqual(document.stringValue, expected)
    }

    // MARK: - Queries

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Post`
    ///   - the model has no eager loaded connections
    ///   - the query is of type `.list`
    /// - Then:
    ///   - check if the generated GraphQL document is valid query:
    ///     - it contains an `filter` argument of type `ModelPostFilterInput`
    ///     - it is named `listPosts`
    ///     - it has a list of fields with no nested/connected models
    ///     - fields are wrapped with `items`
    func testListGraphQLQueryFromSimpleModel() {
        let document = GraphQLQuery(from: Post.self, type: .list)
        let expected = """
        query ListPosts($filter: ModelPostFilterInput) {
          listPosts(filter: $filter) {
            items {
              id
              content
              createdAt
              draft
              rating
              title
              updatedAt
            }
          }
        }
        """
        XCTAssertEqual(document.stringValue, expected)
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
    ///     - it has a list of fields with no nested/connected models
    func testGetGraphQLQueryFromSimpleModel() {
        let document = GraphQLQuery(from: Post.self, type: .get)
        let expected = """
        query GetPost($id: ID!) {
          getPost(id: $id) {
            id
            content
            createdAt
            draft
            rating
            title
            updatedAt
          }
        }
        """
        XCTAssertEqual(document.stringValue, expected)
    }

    // MARK: - Subscriptions

    /// - Given: a `Model` type
    /// - When:
    ///   - the model has no eager loaded connections
    ///   - the subscription is of type `.onCreate`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid subscription
    ///     - it has a list of fields with no nested/connected models
    func testOnCreateGraphQLSubscriptionFromSimpleModel() {
        let document = GraphQLSubscription(of: Post.self, type: .onCreate)
        let expected = """
        subscription OnCreatePost {
          onCreatePost {
            id
            content
            createdAt
            draft
            rating
            title
            updatedAt
          }
        }
        """
        XCTAssertEqual(document.stringValue, expected)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model has no eager loaded connections
    ///   - the subscription is of type `.onUpdate`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid subscription
    ///     - it has a list of fields with no nested/connected models
    func testOnUpdateGraphQLSubscriptionFromSimpleModel() {
        let document = GraphQLSubscription(of: Post.self, type: .onUpdate)
        let expected = """
        subscription OnUpdatePost {
          onUpdatePost {
            id
            content
            createdAt
            draft
            rating
            title
            updatedAt
          }
        }
        """
        XCTAssertEqual(document.stringValue, expected)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model has no eager loaded connections
    ///   - the subscription is of type `.onDelete`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid subscription
    ///     - it has a list of fields with no nested/connected models
    func testOnDeleteGraphQLSubscriptionFromSimpleModel() {
        let document = GraphQLSubscription(of: Post.self, type: .onDelete)
        let expected = """
        subscription OnDeletePost {
          onDeletePost {
            id
            content
            createdAt
            draft
            rating
            title
            updatedAt
          }
        }
        """
        XCTAssertEqual(document.stringValue, expected)
    }
}
