//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify

final class GraphQLTodo13Tests: AWSAPIPluginGen2GraphQLBaseTest {

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/customize-authz/public-data-access/#add-public-authorization-rule-using-amazon-cognito-identity-pools-unauthenticated-role
    func testCodeSnippet() async throws {
        await setup(withModels: Todo13Models(), withAuthPlugin: true)
        await AuthSignInHelper.signOut()
        // Code Snippet begins
        do {
            let todo = Todo(content: "My new todo")
            let createdTodo = try await Amplify.API.mutate(request: .create(
                todo,
                authMode: .awsIAM)).get()
            // Code Snippet Ends
            XCTAssertEqual(createdTodo.id, todo.id)
            // Code Snippet Begins
        } catch {
            print("Failed to create todo", error)
            // Code Snippet Ends
            XCTFail("Failed to create todo \(error)")
            // Code Snippet Begins
        }
    }
}

extension GraphQLTodo13Tests: DefaultLogger { }

extension GraphQLTodo13Tests {
    typealias Todo = Todo13

    struct Todo13Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Todo13.self)
        }
    }
}
