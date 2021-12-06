//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Foundation
import Combine

@testable import Amplify
@testable import AmplifyPlugins
@testable import AmplifyTestCommon

class AWSDataStoreMultiAuthSingleRuleTests: AWSDataStoreAuthBaseTest {
    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent with CognitoUserPools
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for an authenticated users
    func testOwnerUserPools() {
        setup(withModels: UserPoolsOwnerModels(), testType: .multiAuth)

        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: OwnerUPPost.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        // Mutations
        assertMutations(model: OwnerUPPost(name: "name"), expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: a user signed in with OIDC
    /// When: DataStore query/mutation operations are sent with OIDC
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for an authenticated users
    func testOwnerOIDC() throws {
        // PLACEHOLDER
        throw XCTSkip("Not implemented")
    }

    /// Given: a user part of "Admins" group signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent with CognitoUserPools
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for an authenticated users
    func testGroupUserPools() {
        setup(withModels: UserPoolsGroupModels(), testType: .multiAuth)

        // user1 is part of the "Admins" group
        signIn(user: user1)

        let expectations = makeExpectations()
        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: GroupUPPost.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        // Mutation
        assertMutations(model: GroupUPPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: a user who doesn't belong to "Admins" groups signed in with CognitoUserPools
    /// When: DataStore.start is called
    /// Then: DataStore is successfully initialized
    func testGroupUserPoolsWithNonAdminsUser() {
        setup(withModels: UserPoolsGroupModels(), testType: .multiAuth)

        // user2 is not part of the "Admins" group
        signIn(user: user2)

        let expectations = makeExpectations()

        // we're only interested in "ready-state" expectations
        expectations.query.fulfill()
        expectations.mutationSave.fulfill()
        expectations.mutationSaveProcessed.fulfill()
        expectations.mutationDelete.fulfill()
        expectations.mutationDeleteProcessed.fulfill()

        // GroupUPPost won't sync for user2 but DataStore should reach a
        // "ready" state
        expectations.modelsSynced.fulfill()
        assertDataStoreReady(expectations, expectedModelSynced: 0)

        assertUsedAuthTypes([.amazonCognitoUserPools])

        wait(for: [
                expectations.query,
                expectations.mutationSave,
                expectations.mutationSaveProcessed,
                expectations.mutationDelete,
                expectations.mutationDeleteProcessed], timeout: TestCommonConstants.networkTimeout)
    }

    func testGroupOIDC() throws {
        // PLACEHOLDER
        throw XCTSkip("Not implemented")
    }

    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent with CognitoUserPools
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for authenticated users
    func testPrivateUserPools() {
        setup(withModels: UserPoolsPrivateModels(), testType: .multiAuth)

        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        assertQuerySuccess(modelType: PrivateUPPost.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        // Mutations
        assertMutations(model: PrivateUPPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: a user signed in with IAM
    /// When: DataStore query/mutation operations are sent with IAM
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for authenticated users
    func testPrivateIAM() {
        setup(withModels: IAMPrivateModels(), testType: .multiAuth)

        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        assertQuerySuccess(modelType: PrivateIAMPost.self,
                           expectations, onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: PrivateIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.awsIAM])
    }

    /// Given: a schema with a single IAM rule
    /// When: DataStore query/mutation operations are sent with IAM auth for all users
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed for all users
    func testPublicIAM() {
        setup(withModels: IAMPublicModels(), testType: .multiAuth)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: PublicIAMPost.self,
                           expectations, onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: PublicIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.awsIAM])
    }

    /// Given: a schema with a single API key rule
    /// When: DataStore query/mutation operations are sent with API key for all users
    /// Then: DataStore is successfully initialized, query returns a result,
    ///      mutation is processed
    func testPublicAPIKey() {
        setup(withModels: APIKeyPublicModels(), testType: .multiAuth)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: PublicAPIPost.self,
                           expectations, onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: PublicAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.apiKey])
    }

}
