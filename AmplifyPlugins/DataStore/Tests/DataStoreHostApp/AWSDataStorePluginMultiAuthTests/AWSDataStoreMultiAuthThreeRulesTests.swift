//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
import XCTest

@testable import Amplify

class AWSDataStoreMultiAuthThreeRulesTests: AWSDataStoreAuthBaseTest {

    // MARK: - owner/private/public - User Pools, IAM & API Key
    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent
    ///   with Cognito auth for authenticated users
    ///
    /// Note: IAM auth would likely not be used on the client, since it is unlikely that the request would
    /// fail with User Pool auth but succeed with IAM auth for an authenticated user.
    func testOwnerPrivatePublicUserPoolsIAMAPIKeyAuthenticatedUsers() {
        setup(withModels: OwnerPrivatePublicUserPoolsAPIKeyModels(),
              testType: .multiAuth)
        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: OwnerPrivatePublicUPIAMAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: OwnerPrivatePublicUPIAMAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API Key
    func testOwnerPrivatePublicUserPoolsIAMAPIKeyUnauthenticatedUsers() {
        setup(withModels: OwnerPrivatePublicUserPoolsAPIKeyModels(),
              testType: .multiAuth)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: OwnerPrivatePublicUPIAMAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: OwnerPrivatePublicUPIAMAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.apiKey])
    }
}

// MARK: - group/private/public - User Pools, IAM & API Key

extension AWSDataStoreMultiAuthThreeRulesTests {
    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent
    ///   with Cognito auth for authenticated users
    func testGroupPrivatePublicUserPoolsIAMAPIKeyAuthenticatedUsers() {
        setup(withModels: GroupPrivatePublicUserPoolsAPIKeyModels(),
              testType: .multiAuth)
        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: GroupPrivatePublicUPIAMAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: GroupPrivatePublicUPIAMAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API Key
    func testGroupPrivatePublicUserPoolsIAMAPIKeyUnauthenticatedUsers() {
        setup(withModels: GroupPrivatePublicUserPoolsAPIKeyModels(),
              testType: .multiAuth)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: GroupPrivatePublicUPIAMAPIPost.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        // Mutation
        assertMutations(model: GroupPrivatePublicUPIAMAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.apiKey])
    }
}

// MARK: - private/private/public - User Pools, IAM & IAM
extension AWSDataStoreMultiAuthThreeRulesTests {
    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent
    ///   with Cognito
    func testPrivatePrivatePublicUserPoolsIAMIAMAuthenticatedUsers() {
        setup(withModels: PrivatePrivatePublicUserPoolsIAMIAM(),
              testType: .multiAuth)
        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: PrivatePrivatePublicUPIAMIAMPost.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        // Mutation
        assertMutations(model: PrivatePrivatePublicUPIAMIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with IAM
    func testPrivatePrivatePublicUserPoolsIAMIAMUnauthenticatedUsers() {
        setup(withModels: PrivatePrivatePublicUserPoolsIAMIAM(),
              testType: .multiAuth)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: PrivatePrivatePublicUPIAMIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: PrivatePrivatePublicUPIAMIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.awsIAM])
    }
}

// MARK: - private/private/public - User Pools, IAM & API Key
extension AWSDataStoreMultiAuthThreeRulesTests {
    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent
    ///   with Cognito
    func testPrivatePrivatePublicUserPoolsIAMApiKeyAuthenticatedUsers() {
        setup(withModels: PrivatePrivatePublicUserPoolsIAMAPiKey(),
              testType: .multiAuth)
        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: PrivatePrivatePublicUPIAMAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: PrivatePrivatePublicUPIAMAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API Key
    /// Note: IAM auth would likely not be used on the client, since it is unlikely that the request would fail with
    ///     User Pool auth but succeed with IAM auth for an authenticated user.
    func testPrivatePrivatePublicUserPoolsIAMApiKeyUnauthenticatedUsers() {
        setup(withModels: PrivatePrivatePublicUserPoolsIAMAPiKey(),
              testType: .multiAuth)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: PrivatePrivatePublicUPIAMAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: PrivatePrivatePublicUPIAMAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.apiKey])
    }
}

// MARK: - private/public/public - User Pools, API Key & IAM
extension AWSDataStoreMultiAuthThreeRulesTests {
    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent
    ///   with Cognito
    func testPrivatePublicPublicUserPoolsAPIKeyIAMAuthenticatedUsers() {
        setup(withModels: PrivatePublicPublicUserPoolsAPIKeyIAM(),
              testType: .multiAuth)
        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: PrivatePublicPublicUPAPIIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: PrivatePublicPublicUPAPIIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with IAM
    /// Note: API key auth would likely not be used on the client, since it is unlikely that the request would fail with
    ///     public IAM auth but succeed with API key auth.
    func testPrivatePublicPublicUserPoolsAPIKeyIAMUnauthenticatedUsers() {
        setup(withModels: PrivatePublicPublicUserPoolsAPIKeyIAM(),
              testType: .multiAuth)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: PrivatePublicPublicUPAPIIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutations
        assertMutations(model: PrivatePublicPublicUPAPIIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.awsIAM])
    }
}
