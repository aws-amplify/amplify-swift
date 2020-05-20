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
        let post = Post(title: "title", content: "content", createdAt: Date())
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .create))
        documentBuilder.add(decorator: ModelDecorator(model: post))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.create(post)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
        XCTAssert(request.variables != nil)
    }

    func testUpdateMutationGraphQLRequest() {
        let post = Post(title: "title", content: "content", createdAt: Date())
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .update))
        documentBuilder.add(decorator: ModelDecorator(model: post))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.update(post)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
        XCTAssert(request.variables != nil)
    }

    func testDeleteMutationGraphQLRequest() {
        let post = Post(title: "title", content: "content", createdAt: Date())
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .delete))
        documentBuilder.add(decorator: ModelDecorator(model: post))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.delete(post)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
        XCTAssert(request.variables != nil)
    }

    func testQueryByIdGraphQLRequest() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: "id"))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.get(Post.self, byId: "id")

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post?.self)
        XCTAssert(request.variables != nil)
    }

    func testListQueryGraphQLRequest() {
        let post = Post.keys
        let predicate = post.id.eq("id") && (post.title.beginsWith("Title") || post.content.contains("content"))

        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .list))
        documentBuilder.add(decorator: FilterDecorator(filter: predicate.graphQLFilter))
        documentBuilder.add(decorator: PaginationDecorator())
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.list(Post.self, where: predicate)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == [Post].self)
        XCTAssertNotNil(request.variables)
    }

    func testOnCreateSubscriptionGraphQLRequest() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.subscription(of: Post.self, type: .onCreate)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)

    }

    func testOnUpdateSubscriptionGraphQLRequest() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onUpdate))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.subscription(of: Post.self, type: .onUpdate)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
    }

    func testOnDeleteSubscriptionGraphQLRequest() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: Post.self, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onDelete))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.subscription(of: Post.self, type: .onDelete)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
    }
}
