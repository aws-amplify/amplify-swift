//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify

final class GraphQLTodo12Tests: AWSAPIPluginGen2GraphQLBaseTest {

    // Code Snippet for
    // https://docs.amplify.aws/react/build-a-backend/data/customize-authz/public-data-access/#add-public-authorization-rule-using-api-key-based-authentication
    func testCodeSnippet() async throws {
        await setup(withModels: Todo12Models())
        
        // Code Snippet begins
        do {
            let todo = Todo(content: "My new todo")
            let createdTodo = try await Amplify.API.mutate(request: .create(
                todo,
                authMode: .apiKey)).get()
        } catch {
            print("Failed to create todo", error)
            // Code Snippet Ends
            XCTFail("Failed to create todo \(error)")
            // Code Snippet Begins
        }
    }
}

extension GraphQLTodo12Tests: DefaultLogger { }

extension GraphQLTodo12Tests {
    typealias Todo = Todo12

    struct Todo12Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Todo12.self)
        }
    }
}
