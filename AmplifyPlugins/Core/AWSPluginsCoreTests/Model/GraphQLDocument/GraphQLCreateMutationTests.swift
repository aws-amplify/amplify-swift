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

class GraphQLCreateMutationTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: Comment.self)
        ModelRegistry.register(modelType: Post.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

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
        let post = Post(title: "title",
                        content: "content",
                        createdAt: .now(),
                        status: .private)
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .create))
        documentBuilder.add(decorator: ModelDecorator(model: post))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation CreatePost($input: CreatePostInput!) {
          createPost(input: $input) {
            id
            content
            createdAt
            draft
            rating
            status
            title
            updatedAt
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "createPost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.name, "createPost")
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertNotNil(variables["input"])
        guard let input = variables["input"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }
        XCTAssertEqual(input["title"] as? String, post.title)
        XCTAssertEqual(input["content"] as? String, post.content)
        XCTAssertEqual(input["status"] as? String, PostStatus.private.rawValue)
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
        let post = Post(title: "title", content: "content", createdAt: .now())
        let comment = Comment(content: "comment", createdAt: .now(), post: post)
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Comment.schema, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .create))
        documentBuilder.add(decorator: ModelDecorator(model: comment))
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation CreateComment($input: CreateCommentInput!) {
          createComment(input: $input) {
            id
            content
            createdAt
            post {
              id
              content
              createdAt
              draft
              rating
              status
              title
              updatedAt
              __typename
            }
            __typename
          }
        }
        """
        XCTAssertEqual(document.name, "createComment")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.name, "createComment")
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        guard let input = variables["input"] as? GraphQLInput else {
            XCTFail("Variables should contain a valid input")
            return
        }
        XCTAssertEqual(input["commentPostId"] as? String, post.id)
    }

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
    func testCreateGraphQLMutationFromSimpleModelWithSyncEnabled() {
        let post = Post(title: "title", content: "content", createdAt: .now())
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .create))
        documentBuilder.add(decorator: ModelDecorator(model: post))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation CreatePost($input: CreatePostInput!) {
          createPost(input: $input) {
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
        }
        """
        XCTAssertEqual(document.name, "createPost")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.name, "createPost")
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        XCTAssertNotNil(variables["input"])
        guard let input = variables["input"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }
        XCTAssert(input["title"] as? String == post.title)
        XCTAssert(input["content"] as? String == post.content)
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
    func testCreateGraphQLMutationFromModelWithAssociationWithSyncEnabled() {
        let post = Post(title: "title", content: "content", createdAt: .now())
        let comment = Comment(content: "comment", createdAt: .now(), post: post)

        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Comment.schema, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .create))
        documentBuilder.add(decorator: ModelDecorator(model: comment))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation CreateComment($input: CreateCommentInput!) {
          createComment(input: $input) {
            id
            content
            createdAt
            post {
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
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        XCTAssertEqual(document.name, "createComment")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        XCTAssertEqual(document.name, "createComment")
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        guard let input = variables["input"] as? GraphQLInput else {
            XCTFail("Variables should contain a valid input")
            return
        }
        XCTAssertEqual(input["commentPostId"] as? String, post.id)
    }

    func testCreateGraphQLMutationFromModelWithReadonlyFields() {
        let record = Record(name: "name", description: "description")
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Record.schema,
                                                               operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .create))
        documentBuilder.add(decorator: ModelDecorator(model: record))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()
        let expectedQueryDocument = """
        mutation CreateRecord($input: CreateRecordInput!) {
          createRecord(input: $input) {
            id
            createdAt
            description
            name
            updatedAt
            __typename
            _version
            _deleted
            _lastChangedAt
          }
        }
        """
        XCTAssertEqual(document.name, "createRecord")
        XCTAssertEqual(document.stringValue, expectedQueryDocument)
        guard let variables = document.variables else {
            XCTFail("The document doesn't contain variables")
            return
        }
        guard let input = variables["input"] as? GraphQLInput else {
            XCTFail("Variables should contain a valid input")
            return
        }
        XCTAssertEqual(input["id"] as? String, record.id)
        XCTAssertEqual(input["name"] as? String, record.name)
        XCTAssertEqual(input["description"] as? String, record.description)
        XCTAssertNil(input["createdAt"] as? Temporal.DateTime)
        XCTAssertNil(input["updatedAt"] as? Temporal.DateTime)
    }
}
