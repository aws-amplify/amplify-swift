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
        let testId = UUID().uuidString
        await setup(withModels: OwnerPrivatePublicUserPoolsAPIKeyModels(),
                    testType: .multiAuth,
                    testId: testId)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.amazonCognitoUserPools])

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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API Key
    func testOwnerPrivatePublicUserPoolsIAMAPIKeyUnauthenticatedUsers() async {
        let testId = UUID().uuidString
        await setup(withModels: OwnerPrivatePublicUserPoolsAPIKeyModels(),
                    testType: .multiAuth,
                    testId: testId)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.apiKey])

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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
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
        let testId = UUID().uuidString
        await setup(withModels: GroupPrivatePublicUserPoolsAPIKeyModels(),
                    testType: .multiAuth,
                    testId: testId)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.amazonCognitoUserPools])

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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API Key
    func testGroupPrivatePublicUserPoolsIAMAPIKeyUnauthenticatedUsers() async {
        let testId = UUID().uuidString
        await setup(withModels: GroupPrivatePublicUserPoolsAPIKeyModels(),
                    testType: .multiAuth,
                    testId: testId)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.apiKey])

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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
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
        let testId = UUID().uuidString
        await setup(withModels: PrivatePrivatePublicUserPoolsIAMIAM(),
                    testType: .multiAuth,
                    testId: testId)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.amazonCognitoUserPools])

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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with IAM
    func testPrivatePrivatePublicUserPoolsIAMIAMUnauthenticatedUsers() async {
        let testId = UUID().uuidString
        await setup(withModels: PrivatePrivatePublicUserPoolsIAMIAM(),
                    testType: .multiAuth,
                    testId: testId)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.awsIAM])

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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
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
        let testId = UUID().uuidString
        await setup(withModels: PrivatePrivatePublicUserPoolsIAMAPiKey(),
                    testType: .multiAuth,
                    testId: testId)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.amazonCognitoUserPools])

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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API Key
    /// Note: IAM auth would likely not be used on the client, since it is unlikely that the request would fail with
    ///     User Pool auth but succeed with IAM auth for an authenticated user.
    func testPrivatePrivatePublicUserPoolsIAMApiKeyUnauthenticatedUsers() async {
        let testId = UUID().uuidString
        await setup(withModels: PrivatePrivatePublicUserPoolsIAMAPiKey(),
                    testType: .multiAuth,
                    testId: testId)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.apiKey])

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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
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
        let testId = UUID().uuidString
        await setup(withModels: PrivatePublicPublicUserPoolsAPIKeyIAM(),
                    testType: .multiAuth,
                    testId: testId)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.amazonCognitoUserPools])

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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with IAM
    /// Note: API key auth would likely not be used on the client, since it is unlikely that the request would fail with
    ///     public IAM auth but succeed with API key auth.
    func testPrivatePublicPublicUserPoolsAPIKeyIAMUnauthenticatedUsers() async {
        let testId = UUID().uuidString
        await setup(withModels: PrivatePublicPublicUserPoolsAPIKeyIAM(),
                    testType: .multiAuth,
                    testId: testId)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.awsIAM])

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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
    }
}
