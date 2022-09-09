//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
import XCTest
import AWSAPIPlugin

@testable import Amplify

// swiftlint:disable file_length
class AWSDataStoreMultiAuthTwoRulesTests: AWSDataStoreAuthBaseTest {
    // MARK: - owner/private - UserPools & IAM

    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations
    /// Then: DataStore is successfully initialized, are sent with CognitoUserPools auth for authenticated users.
    func testOwnerPrivateUserPoolsIAM() async {
        await setup(withModels: OwnerPrivateUserPoolsIAMModels(), testType: .multiAuth)
        await signIn(user: user1)

        let expectations = makeExpectations()
        let model = OwnerPrivateUPIAMPost(name: "name")

        await assertDataStoreReady(expectations)

        await assertQuerySuccess(modelType: OwnerPrivateUPIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: model,
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    // MARK: - owner/public - User Pools & API Key

    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with Cognito
    ///   for authenticated users
    func testOwnerPublicUserPoolsAPIKeyAuthenticatedUsers() async {
        await setup(withModels: OwnerPublicUserPoolsAPIModels(), testType: .multiAuth)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: OwnerPublicUPAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: OwnerPublicUPAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API key
    func testOwnerPublicUserPoolsAPIKeyUnauthenticatedUsers() async {
        await setup(withModels: OwnerPublicUserPoolsAPIModels(), testType: .multiAuth)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: OwnerPublicUPAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: OwnerPublicUPAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.apiKey])
    }

    // MARK: - owner/public - User Pools & IAM

    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent
    ///   with Cognito auth for authenticated users
    func testOwnerPublicUserPoolsIAMAuthenticatedUsers() async {
        await setup(withModels: OwnerPublicUserPoolsIAMModels(), testType: .multiAuth)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: OwnerPublicUPIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: OwnerPublicUPIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }
        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with IAM
    func testOwnerPublicUserPoolsIAMUnauthenticatedUsers() async {
        await setup(withModels: OwnerPublicUserPoolsIAMModels(), testType: .multiAuth)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: OwnerPublicUPIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: OwnerPublicUPIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.awsIAM])
    }

    // MARK: - owner/public - OIDC & API KEY

    /// Given: a user signed in with OIDC
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent\
    ///   with OIDC for authenticated users
    func testOwnerPublicOIDCAPIAuthenticatedUsers() throws {
        // PLACEHOLDER
        throw XCTSkip("Not implemented")
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent
    ///   with API key for unauthenticated users.
    func testOwnerPublicOIDCAPIUnauthenticatedUsers() async {
        await setup(withModels: OwnerPublicOIDCAPIModels(),
              testType: .multiAuth,
              apiPluginFactory: { AWSAPIPlugin(apiAuthProviderFactory: TestAuthProviderFactory()) })

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: OwnerPublicOIDAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: OwnerPublicOIDAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.apiKey])
    }

    // MARK: - group/private - UserPools & IAM

    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent
    ///   with Cognito User Pools auth for authenticated users in the “Admins” group.
    func testGroupPrivateUserPoolsIAM() async {
        await setup(withModels: GroupPrivateUserPoolsIAMModels(), testType: .multiAuth)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: GroupPrivateUPIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: GroupPrivateUPIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }
}

// MARK: - group/public - UserPools & API Key
extension AWSDataStoreMultiAuthTwoRulesTests {
    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent
    ///   with Cognito auth for authenticated users
    func testGroupPublicUserPoolsAPIKeyAuthenticatedUsers() async {
        await setup(withModels: GroupPublicUserPoolsAPIModels(), testType: .multiAuth)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: GroupPublicUPAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: GroupPublicUPAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API Key
    func testGroupPublicUserPoolsAPIKeyUnauthenticatedUsers() async {
        await setup(withModels: GroupPublicUserPoolsAPIModels(), testType: .multiAuth)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: GroupPublicUPAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: GroupPublicUPAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.apiKey])
    }
}

// MARK: - group/public - UserPools & IAM
extension AWSDataStoreMultiAuthTwoRulesTests {
    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent
    ///   with Cognito auth for authenticated users
    func testGroupPublicUserPoolsIAMAuthenticatedUsers() async {
        await setup(withModels: GroupPublicUserPoolsIAMModels(), testType: .multiAuth)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: GroupPublicUPIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: GroupPublicUPIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with IAM
    func testGroupPublicUserPoolsIAMUnauthenticatedUsers() async {
        await setup(withModels: GroupPublicUserPoolsIAMModels(), testType: .multiAuth)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: GroupPublicUPIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: GroupPublicUPIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.awsIAM])
    }
}

// MARK: - private/private - UserPools & IAM
extension AWSDataStoreMultiAuthTwoRulesTests {
    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent
    ///   with Cognito auth for authenticated users
    func testPrivatePrivateUserPoolsIAMAuthenticatedUsers() async {
        await setup(withModels: PrivateUserPoolsIAMModels(), testType: .multiAuth)
        await signIn(user: user1)

        let expectations = makeExpectations()
        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: PrivatePrivateUPIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: PrivatePrivateUPIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }
}

// MARK: - private/public - User Pools & API Key
extension AWSDataStoreMultiAuthTwoRulesTests {
    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with Cognito
    ///   for authenticated users
    func testPrivatePublicUserPoolsAPIKeyAuthenticatedUsers() async {
        await setup(withModels: PrivatePublicUserPoolsAPIModels(), testType: .multiAuth)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: PrivatePublicUPAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: PrivatePublicUPAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API key
    func testPrivatePublicUserPoolsAPIKeyUnauthenticatedUsers() async {
        await setup(withModels: PrivatePublicUserPoolsAPIModels(), testType: .multiAuth)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: PrivatePublicUPAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: PrivatePublicUPAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.apiKey])

    }
}

// MARK: - private/public - User Pools & IAM
extension AWSDataStoreMultiAuthTwoRulesTests {
    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with Cognito
    ///   for authenticated users
    func testPrivatePublicUserPoolsIAMAuthenticatedUsers() async{
        await setup(withModels: PrivatePublicUserPoolsIAMModels(), testType: .multiAuth)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: PrivatePublicUPIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: PrivatePublicUPIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with IAM
    func testPrivatePublicUserPoolsIAMUnauthenticatedUsers() async {
        await setup(withModels: PrivatePublicUserPoolsIAMModels(), testType: .multiAuth)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: PrivatePublicUPIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: PrivatePublicUPIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.awsIAM])
    }
}

// MARK: - private/public - IAM & API Key
extension AWSDataStoreMultiAuthTwoRulesTests {

    /// Given: a user signed in with IAM
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with IAM
    ///   for authenticated users
    func testPrivatePublicIAMAPIKeyAuthenticatedUsers() async {
        await setup(withModels: PrivatePublicIAMAPIModels(), testType: .multiAuth)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: PrivatePublicIAMAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: PrivatePublicIAMAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.awsIAM])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API Key
    func testPrivatePublicIAMAPIKeyUnauthenticatedUsers() async {
        await setup(withModels: PrivatePublicIAMAPIModels(), testType: .multiAuth)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: PrivatePublicIAMAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: PrivatePublicIAMAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.apiKey])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with IAM
    ///   for unauthenticated users
    func testPublicPublicAPIKeyIAMUnauthenticatedUsers() async {
        await setup(withModels: PublicPublicAPIIAMModels(), testType: .multiAuth)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: PublicPublicIAMAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: PublicPublicIAMAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.awsIAM])
    }

}

// MARK: - TestAuthProviderFactory
class TestAuthProviderFactory: APIAuthProviderFactory {

    class TestOIDCAuthProvider: AmplifyOIDCAuthProvider {
        
        func getLatestAuthToken() async throws -> String {
            throw DataStoreError.unknown("Not implemented", "Expected, we're testing unauthorized users.")
        }
        
        func getUserPoolAccessToken() async throws -> String {
            throw DataStoreError.unknown("Not implemented", "Expected, we're testing unauthorized users.")
        }
    }

    override func oidcAuthProvider() -> AmplifyOIDCAuthProvider? {
        TestOIDCAuthProvider()
    }
}
