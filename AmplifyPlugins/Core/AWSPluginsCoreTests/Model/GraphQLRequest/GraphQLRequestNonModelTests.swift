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

class GraphQLRequestNonModelTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: Todo.self)
    }

    override func tearDown() {
        ModelRegistry.reset()
    }

    func testCreateTodoGraphQLRequest() {
        let color1 = Color(name: "color1", red: 1, green: 2, blue: 3)
        let color2 = Color(name: "color2", red: 12, green: 13, blue: 14)
        let category1 = Category(name: "green", color: color1)
        let category2 = Category(name: "red", color: color2)
        let section = Section(name: "section", number: 1.1)
        let todo = Todo(name: "my first todo",
                        description: "todo description",
                        categories: [category1, category2],
                        section: section)
        let documentStringValue = """
        mutation CreateTodo($input: CreateTodoInput!) {
          createTodo(input: $input) {
            id
            categories {
              color {
                blue
                green
                name
                red
                __typename
              }
              name
              __typename
            }
            description
            name
            section {
              name
              number
              __typename
            }
            stickies
            __typename
          }
        }
        """
        let request = GraphQLRequest<Todo>.create(todo)
        XCTAssertEqual(documentStringValue, request.document)

        guard let variables = request.variables else {
            XCTFail("The request doesn't contain variables")
            return
        }
        guard let input = variables["input"] as? [String: Any] else {
            XCTFail("The document variables property doesn't contain a valid input")
            return
        }
        XCTAssertEqual(input["id"] as? String, todo.id)
    }
}
