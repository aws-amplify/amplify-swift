//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify

final class GraphQLPost11Tests: AWSAPIPluginGen2GraphQLBaseTest {

    // Code Snippet for
    // https://docs.amplify.aws/swift/build-a-backend/data/customize-authz/#configure-multiple-authorization-rules
    func testCodeSnippet() async throws {
        await setup(withModels: Post11Models(), withAuthPlugin: true)
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
            let post = Post(title: "Hello World")
            let createdTodo = try await Amplify.API.mutate(request: .create(
                post,
                authMode: .amazonCognitoUserPools)).get()
        } catch {
            print("Failed to create post", error)
            // Code Snippet Ends
            XCTFail("Failed to create post \(error)")
            // Code Snippet Begins
        }

        // Code Snippet ends
        await AuthSignInHelper.signOut()
        // Code Snippet begins

        do {
            let queriedPosts = try await Amplify.API.query(request: .list(
                Post.self,
                authMode: .awsIAM)).get()
            print("Number of posts:", queriedPosts.count)

            // Code Snippet Ends
            XCTAssertTrue(queriedPosts.count > 0 || queriedPosts.hasNextPage())
            // Code Snippet Begins
        } catch {
            print("Failed to list posts", error)
            // Code Snippet Ends
            XCTFail("Failed to list posts \(error)")
            // Code Snippet Begins
        }
    }
}

extension GraphQLPost11Tests: DefaultLogger { }

extension GraphQLPost11Tests {
    typealias Post = Post11

    struct Post11Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Post11.self)
        }
    }
}
