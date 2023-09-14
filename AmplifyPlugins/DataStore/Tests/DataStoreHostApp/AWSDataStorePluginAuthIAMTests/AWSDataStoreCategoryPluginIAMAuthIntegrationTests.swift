//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify

class AWSDataStoreCategoryPluginIAMAuthIntegrationTests: AWSDataStoreAuthBaseTest {

    /// Given: a user signed in with IAM, a model with `allow private`  auth rule with IAM as provider
    /// When: DataStore query/mutation operations are sent with IAM
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for authenticated users
    func testIAMAllowPrivate() async {
        let testId = UUID().uuidString
        await setup(withModels: IAMPrivateModelRegistration(),
                    testType: .defaultAuthIAM,
                    testId: testId)

        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpectation = assertUsedAuthTypes(testId: testId, authTypes: [.awsIAM])

        // Query
        await assertQuerySuccess(modelType: TodoIAMPrivate.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let todo = TodoIAMPrivate(title: "title")

        // Mutations
        await assertMutations(model: todo, expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        await fulfillment(of: [authTypeExpectation], timeout: 5)
    }

    /// Given: a guest user,  a model with `allow public` auth rule with IAM as provider
    /// When: DataStore query/mutation operations are sent with IAM
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for unauthenticated users
    func testIAMAllowPublic() async {
        let testId = UUID().uuidString
        await setup(withModels: IAMPublicModelRegistration(),
                    testType: .defaultAuthIAM,
                    testId: testId)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpectation = assertUsedAuthTypes(testId: testId, authTypes: [.awsIAM])

        // Query
        await assertQuerySuccess(modelType: TodoIAMPublic.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let todo = TodoIAMPublic(title: "title")

        // Mutations
        await assertMutations(model: todo, expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        await fulfillment(of: [authTypeExpectation], timeout: 5)
    }
}

// MARK: - Models registration
extension AWSDataStoreCategoryPluginIAMAuthIntegrationTests {
    struct IAMPrivateModelRegistration: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: TodoIAMPrivate.self)
        }
    }

    struct IAMPublicModelRegistration: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: TodoIAMPublic.self)
        }
    }
}
