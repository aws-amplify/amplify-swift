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

class GraphQLRequestModelTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: Comment.self)
        ModelRegistry.register(modelType: Post.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model is a `Post`
    ///   - the mutation is of type `.create`
    /// - Then:
    ///   - check if the `GraphQLRequest` is valid:
    ///     - the `document` has the right content
    ///     - the `responseType` is correct
    ///     - the `variables` is non-nil
    func testCreateMutationGraphQLRequest() {
        let post = Post(title: "title", content: "content")
        let document = GraphQLMutation(of: post, type: .create)

        let request = GraphQLRequest<Post>.mutation(of: post, type: .create)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
        XCTAssert(request.variables != nil)
    }

    func testUpdateMutationGraphQLRequest() {
        let post = Post(title: "title", content: "content")
        let document = GraphQLMutation(of: post, type: .update)

        let request = GraphQLRequest<Post>.mutation(of: post, type: .update)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
        XCTAssert(request.variables != nil)
    }

    func testDeleteMutationGraphQLRequest() {
        let post = Post(title: "title", content: "content")
        let document = GraphQLMutation(of: post, type: .delete)

        let request = GraphQLRequest<Post>.mutation(of: post, type: .delete)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
        XCTAssert(request.variables != nil)
    }

    func testQueryByIdGraphQLRequest() {
        let document = GraphQLGetQuery(from: Post.self, id: "id")

        let request = GraphQLRequest<Post>.query(from: Post.self, byId: "id")

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post?.self)
        XCTAssert(request.variables != nil)
    }

    func testListQueryGraphQLRequest() {
        let post = Post.keys
        let predicate = post.id.eq("id") && (post.title.beginsWith("Title") || post.content.contains("content"))

        let request = GraphQLRequest<Post>.query(from: Post.self, where: predicate)

        XCTAssert(request.responseType == [Post].self)
        XCTAssertNotNil(request.variables)
    }

    func testOnCreateSubscriptionGraphQLRequest() {
        let document = GraphQLSubscription(of: Post.self, type: .onCreate)

        let request = GraphQLRequest<Post>.subscription(of: Post.self, type: .onCreate)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)

    }

    func testOnUpdateSubscriptionGraphQLRequest() {
        let document = GraphQLSubscription(of: Post.self, type: .onUpdate)

        let request = GraphQLRequest<Post>.subscription(of: Post.self, type: .onUpdate)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
    }

    func testOnDeleteSubscriptionGraphQLRequest() {
        let document = GraphQLSubscription(of: Post.self, type: .onDelete)

        let request = GraphQLRequest<Post>.subscription(of: Post.self, type: .onDelete)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
    }
}
