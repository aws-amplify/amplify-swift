//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class AWSDataStoreCategoryPluginAuthOwnerIntegrationTests: AWSDataStoreAuthBaseTest {

    /// Given: a user signed in with CognitoUserPools, a model with a custom implicit owner
    /// When: DataStore query/mutation operations are sent with CognitoUserPools
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for an authenticated users
    func testImplicitCustomOwner() {
        setup(withModels: CustomOwnerImplicitModelRegistration(),
              testType: .defaultAuthCognito)

        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: TodoCustomOwnerImplicit.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let todo = TodoCustomOwnerImplicit(title: "title")

        // Mutations
        assertMutations(model: todo, expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: a user signed in with CognitoUserPools, a model with a custom explicit owner
    /// When: DataStore query/mutation operations are sent with CognitoUserPools
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for an authenticated users
    func testExplicitCustomOwner() {
        setup(withModels: CustomOwnerExplicitModelRegistration(),
              testType: .defaultAuthCognito)

        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: TodoCustomOwnerExplicit.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let todo = TodoCustomOwnerExplicit(title: "title")

        // Mutations
        assertMutations(model: todo, expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: a user signed in with CognitoUserPools, a model with an explicit owner field
    /// When: DataStore query/mutation operations are sent with CognitoUserPools
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for an authenticated users
    func testExplicitOwner() {
        setup(withModels: ExplicitOwnerModelRegistration(),
              testType: .defaultAuthCognito)

        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: TodoExplicitOwnerField.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let todo = TodoExplicitOwnerField(content: "content")

        // Mutations
        assertMutations(model: todo, expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: a user signed in with CognitoUserPools, a model with an implicit owner field
    /// When: DataStore query/mutation operations are sent with CognitoUserPools
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for an authenticated users
    func testImplicitOwner() {
        setup(withModels: ImplicitOwnerModelRegistration(),
              testType: .defaultAuthCognito)

        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: TodoImplicitOwnerField.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let todo = TodoImplicitOwnerField(content: "content")

        // Mutations
        assertMutations(model: todo, expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: a user signed in with CognitoUserPools, a model with `allow:private` auth rule
    /// When: DataStore query/mutation operations are sent with CognitoUserPools
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for an authenticated users
    func testAllowPrivate() {
        setup(withModels: AllowPrivateModelRegistration(),
              testType: .defaultAuthCognito)

        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: TodoCognitoPrivate.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let todo = TodoCognitoPrivate(title: "title")

        // Mutations
        assertMutations(model: todo, expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

}

// MARK: - Models registration
extension AWSDataStoreCategoryPluginAuthOwnerIntegrationTests {

    struct CustomOwnerImplicitModelRegistration: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: TodoCustomOwnerImplicit.self)
        }
    }

    struct CustomOwnerExplicitModelRegistration: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: TodoCustomOwnerExplicit.self)
        }
    }

    struct ExplicitOwnerModelRegistration: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: TodoExplicitOwnerField.self)
        }
    }

    struct ImplicitOwnerModelRegistration: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: TodoImplicitOwnerField.self)
        }
    }

    struct AllowPrivateModelRegistration: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: TodoCognitoPrivate.self)
        }
    }

}
