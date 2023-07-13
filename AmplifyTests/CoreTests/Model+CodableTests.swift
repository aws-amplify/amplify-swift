//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AmplifyTestCommon

class ModelCodableTests: XCTestCase {
    let postJSONWithFractionalSeconds = """
    {"comments":[],"content":"content","createdAt":"1970-01-12T13:46:40.123Z","id":"post-1","title":"title"}
    """

    let postJSONWithoutFractionalSeconds = """
    {"id":"post-1","title":"title","content":"content","comments":[],"createdAt":"1970-01-12T13:46:40Z"}
    """

    override func setUp() {
        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)
    }

    func testToJSON() throws {
        let createdAt = Temporal.DateTime(Date(timeIntervalSince1970: 1_000_000.123))
        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: createdAt)
        let j = try post.toJSON()
        print(j)
        XCTAssertEqual(try post.toJSON(), postJSONWithFractionalSeconds)
    }

    func testDecodeWithFractionalSeconds() throws {
        let post = try ModelRegistry.decode(modelName: Post.modelName, from: postJSONWithFractionalSeconds) as? Post
        XCTAssertEqual(post?.id, "post-1")
        XCTAssertEqual(post?.title, "title")
        XCTAssertEqual(post?.content, "content")
        XCTAssertEqual(post?.createdAt, Temporal.DateTime(Date(timeIntervalSince1970: 1_000_000.123)))
    }

    func testDecodeWithoutFractionalSeconds() throws {
        let post = try ModelRegistry.decode(modelName: Post.modelName, from: postJSONWithoutFractionalSeconds) as? Post
        XCTAssertEqual(post?.id, "post-1")
        XCTAssertEqual(post?.title, "title")
        XCTAssertEqual(post?.content, "content")
        XCTAssertEqual(post?.createdAt, Temporal.DateTime(Date(timeIntervalSince1970: 1_000_000)))
    }
}
