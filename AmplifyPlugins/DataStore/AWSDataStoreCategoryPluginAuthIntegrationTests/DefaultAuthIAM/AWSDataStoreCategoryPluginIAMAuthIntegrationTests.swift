//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyPlugins
@testable import AmplifyTestCommon

// swiftlint:disable:next type_name
class AWSDataStoreCategoryPluginIAMAuthIntegrationTests: AWSDataStoreAuthBaseTest {

    /// Given: a user signed in with IAM, a model with `allow private`  auth rule with IAM as provider
    /// When: DataStore query/mutation operations are sent with IAM
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for authenticated users
    func testIAMAllowPrivate() {
        setup(withModels: IAMPrivateModelRegistration(),
              testType: .defaultAuthIAM)

        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: TodoIAMPrivate.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let todo = TodoIAMPrivate(title: "title")

        // Mutations
        assertMutations(model: todo, expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.awsIAM])
    }

    /// Given: a guest user,  a model with `allow public` auth rule with IAM as provider
    /// When: DataStore query/mutation operations are sent with IAM
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for unauthenticated users
    func testIAMAllowPublic() {
        setup(withModels: IAMPublicModelRegistration(),
              testType: .defaultAuthIAM)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: TodoIAMPublic.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let todo = TodoIAMPublic(title: "title")

        // Mutations
        assertMutations(model: todo, expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.awsIAM])
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
