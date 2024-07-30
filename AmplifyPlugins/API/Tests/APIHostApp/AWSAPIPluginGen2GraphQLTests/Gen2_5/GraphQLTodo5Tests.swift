//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify

final class GraphQLTodo5Tests: AWSAPIPluginGen2GraphQLBaseTest {

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/identifiers/
    func testCodeSnippet() async throws {
        await setup(withModels: Todo5Models())

        // Code Snippet Begins
        let todo = Todo(
            content: "Buy Milk",
            completed: false)
        let createdTodo = try await Amplify.API.mutate(request: .create(todo)).get()
        print("New Todo created: \(createdTodo)")
        // Code Snippet Ends
        XCTAssertEqual(createdTodo.id, todo.id)
    }
}

extension GraphQLTodo5Tests: DefaultLogger { }

extension GraphQLTodo5Tests {
    typealias Todo = Todo5

    struct Todo5Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Todo5.self)
        }
    }
}
