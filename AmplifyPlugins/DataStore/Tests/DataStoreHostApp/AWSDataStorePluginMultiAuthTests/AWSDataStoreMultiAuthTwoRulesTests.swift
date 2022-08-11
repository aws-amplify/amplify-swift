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
    func testOwnerPrivateUserPoolsIAM() {
        setup(withModels: OwnerPrivateUserPoolsIAMModels(), testType: .multiAuth)
        signIn(user: user1)

        let expectations = makeExpectations()
        let model = OwnerPrivateUPIAMPost(name: "name")

        assertDataStoreReady(expectations)

        assertQuerySuccess(modelType: OwnerPrivateUPIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: model,
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
    func testOwnerPublicUserPoolsAPIKeyAuthenticatedUsers() {
        setup(withModels: OwnerPublicUserPoolsAPIModels(), testType: .multiAuth)
        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: OwnerPublicUPAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: OwnerPublicUPAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API key
    func testOwnerPublicUserPoolsAPIKeyUnauthenticatedUsers() {
        setup(withModels: OwnerPublicUserPoolsAPIModels(), testType: .multiAuth)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: OwnerPublicUPAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: OwnerPublicUPAPIPost(name: "name"),
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
    func testOwnerPublicUserPoolsIAMAuthenticatedUsers() {
        setup(withModels: OwnerPublicUserPoolsIAMModels(), testType: .multiAuth)
        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: OwnerPublicUPIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: OwnerPublicUPIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }
        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with IAM
    func testOwnerPublicUserPoolsIAMUnauthenticatedUsers() {
        setup(withModels: OwnerPublicUserPoolsIAMModels(), testType: .multiAuth)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: OwnerPublicUPIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: OwnerPublicUPIAMPost(name: "name"),
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
    func testOwnerPublicOIDCAPIUnauthenticatedUsers() {
        setup(withModels: OwnerPublicOIDCAPIModels(),
              testType: .multiAuth,
              apiPluginFactory: { AWSAPIPlugin(apiAuthProviderFactory: TestAuthProviderFactory()) })

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: OwnerPublicOIDAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: OwnerPublicOIDAPIPost(name: "name"),
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
    func testGroupPrivateUserPoolsIAM() {
        setup(withModels: GroupPrivateUserPoolsIAMModels(), testType: .multiAuth)
        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: GroupPrivateUPIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: GroupPrivateUPIAMPost(name: "name"),
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
    func testGroupPublicUserPoolsAPIKeyAuthenticatedUsers() {
        setup(withModels: GroupPublicUserPoolsAPIModels(), testType: .multiAuth)
        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: GroupPublicUPAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: GroupPublicUPAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API Key
    func testGroupPublicUserPoolsAPIKeyUnauthenticatedUsers() {
        setup(withModels: GroupPublicUserPoolsAPIModels(), testType: .multiAuth)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: GroupPublicUPAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: GroupPublicUPAPIPost(name: "name"),
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
    func testGroupPublicUserPoolsIAMAuthenticatedUsers() {
        setup(withModels: GroupPublicUserPoolsIAMModels(), testType: .multiAuth)
        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: GroupPublicUPIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: GroupPublicUPIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with IAM
    func testGroupPublicUserPoolsIAMUnauthenticatedUsers() {
        setup(withModels: GroupPublicUserPoolsIAMModels(), testType: .multiAuth)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: GroupPublicUPIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: GroupPublicUPIAMPost(name: "name"),
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
    func testPrivatePrivateUserPoolsIAMAuthenticatedUsers() {
        setup(withModels: PrivateUserPoolsIAMModels(), testType: .multiAuth)
        signIn(user: user1)

        let expectations = makeExpectations()
        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: PrivatePrivateUPIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: PrivatePrivateUPIAMPost(name: "name"),
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
    func testPrivatePublicUserPoolsAPIKeyAuthenticatedUsers() {
        setup(withModels: PrivatePublicUserPoolsAPIModels(), testType: .multiAuth)
        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: PrivatePublicUPAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: PrivatePublicUPAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API key
    func testPrivatePublicUserPoolsAPIKeyUnauthenticatedUsers() {
        setup(withModels: PrivatePublicUserPoolsAPIModels(), testType: .multiAuth)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: PrivatePublicUPAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: PrivatePublicUPAPIPost(name: "name"),
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
    func testPrivatePublicUserPoolsIAMAuthenticatedUsers() {
        setup(withModels: PrivatePublicUserPoolsIAMModels(), testType: .multiAuth)
        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: PrivatePublicUPIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: PrivatePublicUPIAMPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.amazonCognitoUserPools])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with IAM
    func testPrivatePublicUserPoolsIAMUnauthenticatedUsers() {
        setup(withModels: PrivatePublicUserPoolsIAMModels(), testType: .multiAuth)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: PrivatePublicUPIAMPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: PrivatePublicUPIAMPost(name: "name"),
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
    func testPrivatePublicIAMAPIKeyAuthenticatedUsers() {
        setup(withModels: PrivatePublicIAMAPIModels(), testType: .multiAuth)
        signIn(user: user1)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: PrivatePublicIAMAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: PrivatePublicIAMAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.awsIAM])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API Key
    func testPrivatePublicIAMAPIKeyUnauthenticatedUsers() {
        setup(withModels: PrivatePublicIAMAPIModels(), testType: .multiAuth)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: PrivatePublicIAMAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: PrivatePublicIAMAPIPost(name: "name"),
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
    func testPublicPublicAPIKeyIAMUnauthenticatedUsers() {
        setup(withModels: PublicPublicAPIIAMModels(), testType: .multiAuth)

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: PublicPublicIAMAPIPost.self,
                           expectations,
                           onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        assertMutations(model: PublicPublicIAMAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.awsIAM])
    }

}

// MARK: - TestAuthProviderFactory
class TestAuthProviderFactory: APIAuthProviderFactory {

    class TestOIDCAuthProvider: AmplifyOIDCAuthProvider {
        func getLatestAuthToken() -> Result<AuthToken, Error> {
            .failure(DataStoreError.unknown("Not implemented", "Expected, we're testing unauthorized users."))
        }
        func getUserPoolAccessToken() async throws -> String {
            throw DataStoreError.unknown("Not implemented", "Expected, we're testing unauthorized users.")
        }
    }

    override func oidcAuthProvider() -> AmplifyOIDCAuthProvider? {
        TestOIDCAuthProvider()
    }
}
