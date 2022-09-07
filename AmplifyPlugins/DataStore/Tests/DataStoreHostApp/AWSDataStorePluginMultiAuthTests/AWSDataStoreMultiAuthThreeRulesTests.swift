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
    func testOwnerPrivatePublicUserPoolsIAMAPIKeyAuthenticatedUsers() async {
        await setup(withModels: OwnerPrivatePublicUserPoolsAPIKeyModels(),
              testType: .multiAuth)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: OwnerPrivatePublicUPIAMAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: OwnerPrivatePublicUPIAMAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API Key
    func testOwnerPrivatePublicUserPoolsIAMAPIKeyUnauthenticatedUsers() async {
        await setup(withModels: OwnerPrivatePublicUserPoolsAPIKeyModels(),
              testType: .multiAuth)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: OwnerPrivatePublicUPIAMAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: OwnerPrivatePublicUPIAMAPIPost(name: "name"),
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
    func testGroupPrivatePublicUserPoolsIAMAPIKeyAuthenticatedUsers() async {
        await setup(withModels: GroupPrivatePublicUserPoolsAPIKeyModels(),
              testType: .multiAuth)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: GroupPrivatePublicUPIAMAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: GroupPrivatePublicUPIAMAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API Key
    func testGroupPrivatePublicUserPoolsIAMAPIKeyUnauthenticatedUsers() async {
        await setup(withModels: GroupPrivatePublicUserPoolsAPIKeyModels(),
              testType: .multiAuth)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: GroupPrivatePublicUPIAMAPIPost.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        // Mutation
        await assertMutations(model: GroupPrivatePublicUPIAMAPIPost(name: "name"),
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
    func testPrivatePrivatePublicUserPoolsIAMIAMAuthenticatedUsers() async {
        await setup(withModels: PrivatePrivatePublicUserPoolsIAMIAM(),
              testType: .multiAuth)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: PrivatePrivatePublicUPIAMIAMPost.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        // Mutation
        await assertMutations(model: PrivatePrivatePublicUPIAMIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with IAM
    func testPrivatePrivatePublicUserPoolsIAMIAMUnauthenticatedUsers() async {
        await setup(withModels: PrivatePrivatePublicUserPoolsIAMIAM(),
              testType: .multiAuth)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: PrivatePrivatePublicUPIAMIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: PrivatePrivatePublicUPIAMIAMPost(name: "name"),
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
    func testPrivatePrivatePublicUserPoolsIAMApiKeyAuthenticatedUsers() async {
        await setup(withModels: PrivatePrivatePublicUserPoolsIAMAPiKey(),
              testType: .multiAuth)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: PrivatePrivatePublicUPIAMAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: PrivatePrivatePublicUPIAMAPIPost(name: "name"),
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
    func testPrivatePrivatePublicUserPoolsIAMApiKeyUnauthenticatedUsers() async {
        await setup(withModels: PrivatePrivatePublicUserPoolsIAMAPiKey(),
              testType: .multiAuth)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: PrivatePrivatePublicUPIAMAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: PrivatePrivatePublicUPIAMAPIPost(name: "name"),
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
    func testPrivatePublicPublicUserPoolsAPIKeyIAMAuthenticatedUsers() async {
        await setup(withModels: PrivatePublicPublicUserPoolsAPIKeyIAM(),
              testType: .multiAuth)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: PrivatePublicPublicUPAPIIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: PrivatePublicPublicUPAPIIAMPost(name: "name"),
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
    func testPrivatePublicPublicUserPoolsAPIKeyIAMUnauthenticatedUsers() async {
        await setup(withModels: PrivatePublicPublicUserPoolsAPIKeyIAM(),
              testType: .multiAuth)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: PrivatePublicPublicUPAPIIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutations
        await assertMutations(model: PrivatePublicPublicUPAPIIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.awsIAM])
    }
}
