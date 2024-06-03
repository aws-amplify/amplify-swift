//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify

final class GraphQLSalary18Tests: AWSAPIPluginGen2GraphQLBaseTest {

    // Code Snippet for
    func testCodeSnippet() async throws {
        await setup(withModels: Salary18Models(), withAuthPlugin: true)
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
            let salary = Salary(
                wage: 50.25,
                currency: "USD")
            let createdSalary = try await Amplify.API.mutate(request: .create(
                salary,
                authMode: .amazonCognitoUserPools)).get()
            // Code Snippet Ends
            XCTFail("Should not make it to here. Expected to catch failure since user is not in the Admin group.")
            // Code Snippet begins
        } catch {
            print("Failed to create salary", error)
            // Code Snippet Ends
            // Expected to catch failure since the user is not in the Admin group.
            XCTAssertNotNil(error)
            // Code Snippet begins
        }
    }
}

extension GraphQLSalary18Tests: DefaultLogger { }

extension GraphQLSalary18Tests {
    typealias Salary = Salary18

    struct Salary18Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Salary18.self)
        }
    }
}
