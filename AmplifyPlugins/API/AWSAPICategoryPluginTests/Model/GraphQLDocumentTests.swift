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

    override func setUp() {
        ModelRegistry.register(modelType: Comment.self)
        ModelRegistry.register(modelType: Post.self)
    }

    // MARK: - Mutations

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model is of type `Post`
    ///   - the model has no required associations
    ///   - the mutation is of type `.create`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid mutation:
    ///     - it is named `createPost`
    ///     - it contains an `input` of type `CreatePostInput`
    ///     - it has a list of fields with no nested models
    func testCreateGraphQLMutationFromSimpleModel() {
        let post = Post(title: "title", content: "content")
        let document = GraphQLMutation(of: post, type: .create)
        let expected = """
        mutation CreatePost($input: CreatePostInput!) {
          createPost(input: $input) {
            id
            _deleted
            _version
            content
            createdAt
            draft
            rating
            title
            updatedAt
            __typename
          }
        }
        """
        XCTAssertEqual(document.stringValue, expected)
        XCTAssertEqual(document.name, "createPost")
        XCTAssertNotNil(document.variables["input"])
    }

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model is of type `Comment`
    ///   - the model has required associations
    ///   - the mutation is of type `.create`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid mutation:
    ///     - it is named `createComment`
    ///     - it contains an `input` of type `CreateCommentInput`
    ///     - it has a list of fields with a `postId`
    func testCreateGraphQLMutationFromModelWithAssociation() {
        let post = Post(title: "title", content: "content")
        let comment = Comment(content: "comment", post: post)
        let document = GraphQLMutation(of: comment, type: .create)
        let expected = """
        mutation CreateComment($input: CreateCommentInput!) {
          createComment(input: $input) {
            id
            content
            createdAt
            post {
              id
              _deleted
              _version
              content
              createdAt
              draft
              rating
              title
              updatedAt
              __typename
            }
            __typename
          }
        }
        """
        XCTAssertEqual(document.stringValue, expected)
        XCTAssertEqual(document.name, "createComment")
        guard let input = document.variables["input"] as? GraphQLInput else {
            XCTFail("Variables should contain a valid input")
            return
        }
        XCTAssertNotNil(input["commentPostId"])
        XCTAssertEqual(input["commentPostId"] as? String, post.id)
    }

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model is of type `Post`
    ///   - the model has no required associations
    ///   - the mutation is of type `.update`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid mutation:
    ///     - it is named `updatePost`
    ///     - it contains an `input` of type `UpdatePostInput`
    ///     - it has a list of fields with no nested models
    func testUpdateGraphQLMutationFromSimpleModel() {
        let post = Post(title: "title", content: "content")
        let document = GraphQLMutation(of: post, type: .update)
        let expected = """
        mutation UpdatePost($input: UpdatePostInput!) {
          updatePost(input: $input) {
            id
            _deleted
            _version
            content
            createdAt
            draft
            rating
            title
            updatedAt
            __typename
          }
        }
        """
        XCTAssertEqual(document.stringValue, expected)
        XCTAssertEqual(document.name, "updatePost")
        XCTAssertNotNil(document.variables["input"])
    }

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model is of type `Post`
    ///   - the model has no required associations
    ///   - the mutation is of type `.delete`
    /// - Then:
    ///   - check if the generated GraphQL document is a valid mutation:
    ///     - it is named `deletePost`
    ///     - it contains an `input` of type `ID!`
    ///     - it has a list of fields with no nested models
    func testDeleteGraphQLMutationFromSimpleModel() {
        let post = Post(title: "title", content: "content")
        let document = GraphQLMutation(of: post, type: .delete)
        let expected = """
        mutation DeletePost($input: DeletePostInput!) {
          deletePost(input: $input) {
            id
            _deleted
            _version
            content
            createdAt
            draft
            rating
            title
            updatedAt
            __typename
          }
        }
        """
        XCTAssertEqual(document.stringValue, expected)
        XCTAssertEqual(document.name, "deletePost")
        XCTAssert(document.variables["input"] != nil)
        guard let input = document.variables["input"] as? [String: String] else {
            XCTFail("Could not get object at `input`")
            return
        }
        XCTAssertEqual(input["id"], post.id)
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
    ///     - it has a list of fields with no nested models
    ///     - fields are wrapped with `items`
    func testListGraphQLQueryFromSimpleModel() {
        let document = GraphQLQuery(from: Post.self, type: .list)
        let expected = """
        query ListPosts($filter: ModelPostFilterInput, $limit: Int, $nextToken: String) {
          listPosts(filter: $filter, limit: $limit, nextToken: $nextToken) {
            items {
              id
              _deleted
              _version
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
    ///     - it has a list of fields with no nested models
    func testGetGraphQLQueryFromSimpleModel() {
        let document = GraphQLQuery(from: Post.self, type: .get)
        let expected = """
        query GetPost($id: ID!) {
          getPost(id: $id) {
            id
            _deleted
            _version
            content
            createdAt
            draft
            rating
            title
            updatedAt
            __typename
          }
        }
        """
        XCTAssertEqual(document.stringValue, expected)
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
        let document = GraphQLQuery(from: Post.self, type: .sync)
        let expected = """
        query SyncPosts($filter: ModelPostFilterInput, $limit: Int, $nextToken: String) {
          syncPosts(filter: $filter, limit: $limit, nextToken: $nextToken) {
            items {
              id
              _deleted
              _version
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
        XCTAssertEqual(document.stringValue, expected)
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
        let document = GraphQLQuery(from: Comment.self, type: .get)
        let expected = """
        query GetComment($id: ID!) {
          getComment(id: $id) {
            id
            content
            createdAt
            post {
              id
              _deleted
              _version
              content
              createdAt
              draft
              rating
              title
              updatedAt
              __typename
            }
            __typename
          }
        }
        """
        XCTAssertEqual(document.stringValue, expected)
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
        let expected = """
        subscription OnCreatePost {
          onCreatePost {
            id
            _deleted
            _version
            content
            createdAt
            draft
            rating
            title
            updatedAt
            __typename
          }
        }
        """
        XCTAssertEqual(document.stringValue, expected)
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
        let expected = """
        subscription OnCreateComment {
          onCreateComment {
            id
            content
            createdAt
            post {
              id
              _deleted
              _version
              content
              createdAt
              draft
              rating
              title
              updatedAt
              __typename
            }
            __typename
          }
        }
        """
        XCTAssertEqual(document.stringValue, expected)
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
        let expected = """
        subscription OnUpdatePost {
          onUpdatePost {
            id
            _deleted
            _version
            content
            createdAt
            draft
            rating
            title
            updatedAt
            __typename
          }
        }
        """
        XCTAssertEqual(document.stringValue, expected)
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
        let expected = """
        subscription OnDeletePost {
          onDeletePost {
            id
            _deleted
            _version
            content
            createdAt
            draft
            rating
            title
            updatedAt
            __typename
          }
        }
        """
        XCTAssertEqual(document.stringValue, expected)
    }

    // MARK: - GraphQLRequest+Model

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model is a `Post`
    ///   - the mutation is of type `.create`
    /// - Then:
    ///   - check if the `GraphQLRequest` is valid:
    ///     - the `document` has the right content
    ///     - the `variables` has the right keys and values
    func testCreateMutationGraphQLRequest() {
        let post = Post(title: "title", content: "content")
        let document = GraphQLMutation(of: post, type: .create)
        let request = GraphQLRequest<Post>.mutation(of: post, type: .create)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)

        // test the input
        XCTAssert(request.variables != nil)

        guard let input = request.variables?["input"] as? [String: Any] else {
            XCTFail("The request variables property doesn't contain a valid input")
            return
        }
        XCTAssert(input["title"] as? String == post.title)
        XCTAssert(input["content"] as? String == post.content)
    }

    func testListQueryGraphQLRequest() {
        let post = Post.keys
        let predicate = post.id.eq("id") && (post.title.beginsWith("Title") || post.content.contains("content"))
        let request = GraphQLRequest<Post>.query(from: Post.self, where: predicate)
        XCTAssert(request.responseType == [Post].self)
        XCTAssertNotNil(request.variables)
        guard let variables = request.variables else {
            XCTFail("Missing variables")
            return
        }

        XCTAssertNotNil(variables["limit"])
        XCTAssertEqual(variables["limit"] as? Int, 1_000)
        XCTAssertNotNil(variables["filter"])
    }
}
