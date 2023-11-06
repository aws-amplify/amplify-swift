//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore
@testable import Amplify

class AWSDataStoreCategoryPluginAuthOwnerIntegrationTests: AWSDataStoreAuthBaseTest {

    /// Given: a user signed in with CognitoUserPools, a model with a custom implicit owner
    /// When: DataStore query/mutation operations are sent with CognitoUserPools
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for an authenticated users
    func testImplicitCustomOwner() async throws {
        try await setup(withModels: CustomOwnerImplicitModelRegistration(),
              testType: .defaultAuthCognito)

        try await signIn(user: user1)

        let expectations = makeExpectations()

        try await assertDataStoreReady(expectations)

        // Query
        try await assertQuerySuccess(modelType: TodoCustomOwnerImplicit.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let todo = TodoCustomOwnerImplicit(title: "title")

        // Mutations
        try await assertMutations(model: todo, expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: a user signed in with CognitoUserPools, a model with a custom explicit owner
    /// When: DataStore query/mutation operations are sent with CognitoUserPools
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for an authenticated users
    func testExplicitCustomOwner() async throws {
        try await setup(withModels: CustomOwnerExplicitModelRegistration(),
              testType: .defaultAuthCognito)

        try await signIn(user: user1)

        let expectations = makeExpectations()

        try await assertDataStoreReady(expectations)

        // Query
        try await assertQuerySuccess(modelType: TodoCustomOwnerExplicit.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let todo = TodoCustomOwnerExplicit(title: "title")

        // Mutations
        try await assertMutations(model: todo, expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: a user signed in with CognitoUserPools, a model with an explicit owner field
    /// When: DataStore query/mutation operations are sent with CognitoUserPools
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for an authenticated users
    func testExplicitOwner() async throws {
        try await setup(withModels: ExplicitOwnerModelRegistration(),
              testType: .defaultAuthCognito)

        try await signIn(user: user1)

        let expectations = makeExpectations()

        try await assertDataStoreReady(expectations)

        // Query
        try await assertQuerySuccess(modelType: TodoExplicitOwnerField.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let todo = TodoExplicitOwnerField(content: "content")
        
        // Mutations
        try await assertMutations(model: todo, expectations) { error in
            XCTFail("Error mutation \(error)")
        }
        
        assertUsedAuthTypes([.amazonCognitoUserPools])
    }
    
    /// Given: a user signed in with CognitoUserPools, a model with multiple rules with
    ///      explicit owner field
    /// When: DataStore query/mutation operations are sent with CognitoUserPools
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for an authenticated users
    func testExplicitMultipleOwner() async throws {
        try await setup(withModels: ExplicitMultipleOwnerModelRegistration(),
              testType: .defaultAuthCognito)
        
        try await signIn(user: user1)
        
        let expectations = makeExpectations()
        
        try await assertDataStoreReady(expectations)
        
        // Query
        try await assertQuerySuccess(modelType: TodoCognitoMultiOwner.self,
                                     expectations) { error in
            XCTFail("Error query \(error)")
        }
        
        let post = TodoCognitoMultiOwner(title: "title")
        
        // Mutations
        try await assertMutations(model: post, expectations) { error in
            XCTFail("Error mutation \(error)")
        }
        
        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    
    /// Given: a user signed in with CognitoUserPools, a model with an implicit owner field
    /// When: DataStore query/mutation operations are sent with CognitoUserPools
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for an authenticated users
    func testImplicitOwner() async throws {
        try await setup(withModels: ImplicitOwnerModelRegistration(),
              testType: .defaultAuthCognito)

        try await signIn(user: user1)

        let expectations = makeExpectations()

        try await assertDataStoreReady(expectations)

        // Query
        try await assertQuerySuccess(modelType: TodoImplicitOwnerField.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let todo = TodoImplicitOwnerField(content: "content")

        // Mutations
        try await assertMutations(model: todo, expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: a user signed in with CognitoUserPools, a model with `allow:private` auth rule
    /// When: DataStore query/mutation operations are sent with CognitoUserPools
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for an authenticated users
    func testAllowPrivate() async throws {
        try await setup(withModels: AllowPrivateModelRegistration(),
              testType: .defaultAuthCognito)

        try await signIn(user: user1)

        let expectations = makeExpectations()

        try await assertDataStoreReady(expectations)

        // Query
        try await assertQuerySuccess(modelType: TodoCognitoPrivate.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let todo = TodoCognitoPrivate(title: "title")

        // Mutations
        try await assertMutations(model: todo, expectations) { error in
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

    struct ExplicitMultipleOwnerModelRegistration: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: TodoCognitoMultiOwner.self)
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
