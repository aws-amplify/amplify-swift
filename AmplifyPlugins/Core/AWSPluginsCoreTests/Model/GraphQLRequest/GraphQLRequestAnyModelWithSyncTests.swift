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

class GraphQLRequestAnyModelWithSyncTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: Comment.self)
        ModelRegistry.register(modelType: Post.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    func testCreateMutationGraphQLRequest() throws {
        let originalPost = Post(title: "title", content: "content", createdAt: Date())
        let anyPost = try originalPost.eraseToAnyModel()
        var documentBuilder = SingleDirectiveGraphQLDocumentBuilder(modelName: anyPost.modelName,
                                                                    operationType: .mutation)
        documentBuilder.add(decorator: DirectiveDecorator(type: .create))
        documentBuilder.add(decorator: ModelDecorator(model: anyPost))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()

        let request = GraphQLRequest<MutationSyncResult>.createMutation(of: anyPost)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)

        // test the input
        XCTAssert(request.variables != nil)
    }

    func testUpdateMutationGraphQLRequest() throws {
        let originalPost = Post(title: "title", content: "content", createdAt: Date())
        let anyPost = try originalPost.eraseToAnyModel()
        var documentBuilder = SingleDirectiveGraphQLDocumentBuilder(modelName: anyPost.modelName,
                                                                    operationType: .mutation)
        documentBuilder.add(decorator: DirectiveDecorator(type: .update))
        documentBuilder.add(decorator: ModelDecorator(model: anyPost))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()

        let request = GraphQLRequest<MutationSyncResult>.updateMutation(of: anyPost)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)

        // test the input
        XCTAssert(request.variables != nil)
    }

    func testDeleteMutationGraphQLRequest() throws {
        let originalPost = Post(title: "title", content: "content", createdAt: Date())
        let anyPost = try originalPost.eraseToAnyModel()

        var documentBuilder = SingleDirectiveGraphQLDocumentBuilder(modelName: anyPost.modelName,
                                                                    operationType: .mutation)
        documentBuilder.add(decorator: DirectiveDecorator(type: .delete))
        documentBuilder.add(decorator: ModelIdDecorator(id: anyPost.id))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()

        let request = GraphQLRequest<MutationSyncResult>.deleteMutation(modelName: anyPost.modelName, id: anyPost.id)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)

        // test the input
        XCTAssert(request.variables != nil)
    }

    func testCreateSubscriptionGraphQLRequest() throws {
        let modelType = Post.self as Model.Type
        var documentBuilder = SingleDirectiveGraphQLDocumentBuilder(modelType: modelType, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveDecorator(type: .onCreate))
        documentBuilder.add(decorator: ConflictResolutionDecorator())
        let document = documentBuilder.build()

        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType,
                                                                      subscriptionType: .onCreate)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == MutationSyncResult.self)

        // test the input
        XCTAssertNil(request.variables)
    }

    func testSyncQueryGraphQLRequest() throws {

    }
}
