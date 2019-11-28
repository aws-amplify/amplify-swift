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

// TODO: Refactor these tests to share the same execution code
// Shadows tests in the GraphQLDocumentTests suite, but replaces the original models with type erased models
class GraphQLAnyModelDocumentTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: Comment.self)
        ModelRegistry.register(modelType: Post.self)
    }

    // MARK: - Mutations

    func testCreateGraphQLMutationFromSimpleModel() throws {
        let originalPost = Post(title: "title", content: "content")
        let anyPost = try originalPost.eraseToAnyModel()
        let document = GraphQLMutation(of: anyPost, type: .create)
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

    func testUpdateGraphQLMutationFromSimpleModel() throws {
        let originalPost = Post(title: "title", content: "content")
        let anyPost = try originalPost.eraseToAnyModel()
        let document = GraphQLMutation(of: anyPost, type: .update)
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

    func testDeleteGraphQLMutationFromSimpleModel() throws {
        let originalPost = Post(title: "title", content: "content")
        let anyPost = try originalPost.eraseToAnyModel()
        let document = GraphQLMutation(of: anyPost, type: .delete)
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
        XCTAssertEqual(input["id"], originalPost.id)
    }

    // MARK: - GraphQLRequest+Model

    func testCreateMutationGraphQLRequest() throws {
        let originalPost = Post(title: "title", content: "content")
        let anyPost = try originalPost.eraseToAnyModel()
        let document = GraphQLMutation(of: anyPost, type: .create)
        let request = GraphQLRequest<AnyModel>.mutation(of: anyPost, type: .create)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == AnyModel.self)

        // test the input
        XCTAssert(request.variables != nil)

        guard let input = request.variables?["input"] as? [String: Any] else {
            XCTFail("The request variables property doesn't contain a valid input")
            return
        }
        XCTAssert(input["title"] as? String == originalPost.title)
        XCTAssert(input["content"] as? String == originalPost.content)
    }

    func testCreateSubscriptionGraphQLRequest() throws {
        let modelType = Post.self as Model.Type
        let document = GraphQLSubscription(of: modelType, type: .onCreate)
        let request = GraphQLRequest<AnyModel>.subscription(toAnyModelType: modelType,
                                                            subscriptionType: .onCreate)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == AnyModel.self)

        // test the input
        XCTAssertNil(request.variables)
    }

}
