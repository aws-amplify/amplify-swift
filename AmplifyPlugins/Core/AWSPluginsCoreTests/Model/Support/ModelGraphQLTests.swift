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

class ModelGraphQLTests: XCTestCase {

    /// - Given: a `Model` type
    /// - When:
    ///    - the model is of type `Post`
    ///    - the model is initialized with value except `updatedAt` is set to nil
    /// - Then:
    ///    - check if the generated GraphQLInput is valid input:
    ///      - fields other than `updatedAt` has the correct value in them
    ///      - `updatedAt` is nil
    func testPostModelToGraphQLInputSuccess() throws {
        let date: Temporal.DateTime = .now()
        let status = PostStatus.published
        let post = Post(id: "id",
                        title: "title",
                        content: "content",
                        createdAt: date,
                        draft: true,
                        rating: 5.0,
                        status: status)

        let graphQLInput = post.graphQLInput(Post.schema)

        XCTAssertEqual(graphQLInput["title"] as? String, post.title)
        XCTAssertEqual(graphQLInput["content"] as? String, post.content)
        XCTAssertEqual(graphQLInput["createdAt"] as? String, post.createdAt.iso8601String)
        XCTAssertEqual(graphQLInput["draft"] as? Bool, post.draft)
        XCTAssertEqual(graphQLInput["rating"] as? Double, post.rating)
        XCTAssertEqual(graphQLInput["status"] as? String, status.rawValue)

        XCTAssertTrue(graphQLInput.keys.contains("updatedAt"))
        XCTAssertNil(graphQLInput["updatedAt"]!)
    }

    func testTodoModelToGraphQLInputSuccess() {
        let color = Color(name: "red", red: 255, green: 0, blue: 0)
        let category = Category(name: "green", color: color)
        let todo = Todo(name: "name",
                        description: "description",
                        categories: [category],
                        stickies: ["stickie1"])

        let graphQLInput = todo.graphQLInput(Todo.schema)

        XCTAssertEqual(graphQLInput["id"] as? String, todo.id)
        XCTAssertEqual(graphQLInput["name"] as? String, todo.name)
        XCTAssertEqual(graphQLInput["description"] as? String, todo.description)
        guard let categories = graphQLInput["categories"] as? [[String: Any]] else {
            XCTFail("Couldn't get array of categories")
            return
        }
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories[0]["name"] as? String, category.name)
        guard let expectedColor = categories[0]["color"] as? [String: Any] else {
            XCTFail("Couldn't get color in category")
            return
        }
        XCTAssertEqual(expectedColor["name"] as? String, color.name)
        XCTAssertEqual(expectedColor["red"] as? Int, color.red)
        XCTAssertEqual(expectedColor["green"] as? Int, color.green)
        XCTAssertEqual(expectedColor["blue"] as? Int, color.blue)
    }
}
