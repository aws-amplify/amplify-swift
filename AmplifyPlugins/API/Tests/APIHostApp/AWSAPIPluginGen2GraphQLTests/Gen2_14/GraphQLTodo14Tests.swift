//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify

final class GraphQLTodo14Tests: AWSAPIPluginGen2GraphQLBaseTest {

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/customize-authz/per-user-per-owner-data-access/#add-per-userper-owner-authorization-rule
    func testCodeSnippet() async throws {
        await setup(withModels: Todo14Models(), withAuthPlugin: true)
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

extension GraphQLTodo14Tests: DefaultLogger { }

extension GraphQLTodo14Tests {
    typealias Todo = Todo14

    struct Todo14Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Todo14.self)
        }
    }
}
