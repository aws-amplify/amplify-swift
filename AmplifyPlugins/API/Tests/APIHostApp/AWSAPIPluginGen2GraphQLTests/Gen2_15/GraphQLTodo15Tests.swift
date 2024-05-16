//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify

final class GraphQLTodo15Tests: AWSAPIPluginGen2GraphQLBaseTest {

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/customize-authz/multi-user-data-access/#add-multi-user-authorization-rule
    func testCodeSnippet() async throws {
        await setup(withModels: Todo15Models(), withAuthPlugin: true)
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

    func testAddAnotherUserAsAnOwner() async throws {
        await setup(withModels: Todo15Models(), withAuthPlugin: true)
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
        let todo = Todo(content: "My new todo")
        var createdTodo = try await Amplify.API.mutate(request: .create(
            todo,
            authMode: .amazonCognitoUserPools)).get()
        let otherUserId = "otherUserId"

        // Code Snippet begins
        do {
            createdTodo.owners?.append(otherUserId)
            let updatedTodo = try await Amplify.API.mutate(request: .update(
                createdTodo,
                authMode: .amazonCognitoUserPools)).get()
            // Code Snippet Ends
            XCTAssertEqual(updatedTodo.id, todo.id)
            XCTAssertEqual(updatedTodo.owners?.count, 2)
            // Code Snippet Begins
        } catch {
            print("Failed to update todo", error)
            // Code Snippet Ends
            XCTFail("Failed to update todo \(error)")
            // Code Snippet Begins
        }
    }
}

extension GraphQLTodo15Tests: DefaultLogger { }

extension GraphQLTodo15Tests {
    typealias Todo = Todo15

    struct Todo15Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Todo15.self)
        }
    }
}
