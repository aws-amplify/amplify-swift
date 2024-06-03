//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify

final class GraphQLTodo16Tests: AWSAPIPluginGen2GraphQLBaseTest {

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/customize-authz/signed-in-user-data-access/#add-signed-in-user-authorization-rule
    func testCodeSnippet() async throws {
        await setup(withModels: Todo16Models(), withAuthPlugin: true)
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        do {
            _ = try await AuthSignInHelper.registerAndSignInUser(
                username: username,
                password: password,
                email: defaultTestEmail)
        } catch {
            XCTFail("Could not sign up and sign in user \(error)")
        }

        // Code Snippet begins
        do {
            let todo = Todo(content: "My new todo")
            let createdTodo = try await Amplify.API.mutate(request: .create(
                todo,
                authMode: .amazonCognitoUserPools)).get()
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

extension GraphQLTodo16Tests: DefaultLogger { }

extension GraphQLTodo16Tests {
    typealias Todo = Todo16

    struct Todo16Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Todo16.self)
        }
    }
}
