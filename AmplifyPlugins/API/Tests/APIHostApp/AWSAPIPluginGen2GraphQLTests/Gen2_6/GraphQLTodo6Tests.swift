//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify

final class GraphQLTodo6Tests: AWSAPIPluginGen2GraphQLBaseTest {

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/identifiers/#single-field-identifier
    func testCodeSnippet() async throws {
        await setup(withModels: Todo6Models())

        do {
            // Code Snippet Begins
            let todo = Todo(
                todoId: "MyUniqueTodoId",
                content: "Buy Milk",
                completed: false)
            let createdTodo = try await Amplify.API.mutate(request: .create(todo)).get()
            print("New Todo created: \(createdTodo)")
            // Code Snippet Ends
        } catch {
        }
    }
}

extension GraphQLTodo6Tests: DefaultLogger { }

extension GraphQLTodo6Tests {
    typealias Todo = Todo6

    struct Todo6Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Todo6.self)
        }
    }
}
