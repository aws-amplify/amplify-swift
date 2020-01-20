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

class GraphQLRequestAnyModelTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: Comment.self)
        ModelRegistry.register(modelType: Post.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    // MARK: - Mutations

    func testCreateGraphQLMutationFromSimpleModel() throws {
        let originalPost = Post(title: "title", content: "content", createdAt: Date())
        let anyPost = try originalPost.eraseToAnyModel()

        let document = GraphQLMutation(of: anyPost, type: .create)

        XCTAssertEqual(document.name, "createPost")
        XCTAssertEqual(document.decodePath, "createPost")
        XCTAssertNotNil(document.stringValue)
        XCTAssertNotNil(document.variables["input"])
    }

    func testUpdateGraphQLMutationFromSimpleModel() throws {
        let originalPost = Post(title: "title", content: "content", createdAt: Date())
        let anyPost = try originalPost.eraseToAnyModel()

        let document = GraphQLMutation(of: anyPost, type: .update)

        XCTAssertEqual(document.name, "updatePost")
        XCTAssertEqual(document.decodePath, "updatePost")
        XCTAssertNotNil(document.stringValue)
        XCTAssertEqual(document.name, "updatePost")
        XCTAssertNotNil(document.variables["input"])
    }

    func testDeleteGraphQLMutationFromSimpleModel() throws {
        let originalPost = Post(title: "title", content: "content", createdAt: Date())
        let anyPost = try originalPost.eraseToAnyModel()
        let document = GraphQLMutation(of: anyPost, type: .delete)

        XCTAssertEqual(document.name, "deletePost")
        XCTAssertEqual(document.decodePath, "deletePost")
        XCTAssertNotNil(document.stringValue)
        XCTAssertNotNil(document.variables["input"])
        XCTAssert(document.variables["input"] != nil)
        guard let input = document.variables["input"] as? [String: String] else {
            XCTFail("Could not get object at `input`")
            return
        }
        XCTAssertEqual(input["id"], originalPost.id)
    }

    // MARK: - GraphQLRequest+AnyModel

    func testCreateMutationGraphQLRequest() throws {
        let originalPost = Post(title: "title", content: "content", createdAt: Date())
        let anyPost = try originalPost.eraseToAnyModel()
        let document = GraphQLMutation(of: anyPost, type: .create)
        let request = GraphQLRequest<AnyModel>.mutation(of: anyPost, type: .create)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == AnyModel.self)

        // test the input
        XCTAssert(request.variables != nil)
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
