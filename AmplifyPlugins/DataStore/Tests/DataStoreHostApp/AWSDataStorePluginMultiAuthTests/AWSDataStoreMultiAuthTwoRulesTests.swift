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
        let testId = UUID().uuidString
        await setup(withModels: OwnerPrivateUserPoolsIAMModels(), testType: .multiAuth, testId: testId)
        await signIn(user: user1)

        let expectations = makeExpectations()
        let model = OwnerPrivateUPIAMPost(name: "name")

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.amazonCognitoUserPools])
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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
    }

    // MARK: - owner/public - User Pools & API Key

    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with Cognito
    ///   for authenticated users
    func testOwnerPublicUserPoolsAPIKeyAuthenticatedUsers() async {
        let testId = UUID().uuidString
        await setup(withModels: OwnerPublicUserPoolsAPIModels(), testType: .multiAuth, testId: testId)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.amazonCognitoUserPools])
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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API key
    func testOwnerPublicUserPoolsAPIKeyUnauthenticatedUsers() async {
        let testId = UUID().uuidString
        await setup(withModels: OwnerPublicUserPoolsAPIModels(), testType: .multiAuth, testId: testId)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.apiKey])
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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
    }

    // MARK: - owner/public - User Pools & IAM

    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent
    ///   with Cognito auth for authenticated users
    func testOwnerPublicUserPoolsIAMAuthenticatedUsers() async {
        let testId = UUID().uuidString
        await setup(withModels: OwnerPublicUserPoolsIAMModels(), testType: .multiAuth, testId: testId)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.amazonCognitoUserPools])
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
        await fulfillment(of: [authTypeExpecation], timeout: 5)
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with IAM
    func testOwnerPublicUserPoolsIAMUnauthenticatedUsers() async {
        let testId = UUID().uuidString
        await setup(withModels: OwnerPublicUserPoolsIAMModels(), testType: .multiAuth, testId: testId)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.awsIAM])
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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
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
        let testId = UUID().uuidString
        await setup(
            withModels: OwnerPublicOIDCAPIModels(),
            testType: .multiAuth,
            testId: testId,
            apiPluginFactory: {
                AWSAPIPlugin(
                    sessionFactory: DataStoreAuthBaseTestURLSessionFactory(),
                    apiAuthProviderFactory: TestAuthProviderFactory()
                )
            }
        )

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.apiKey])
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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
    }

    // MARK: - group/private - UserPools & IAM

    /// Given: a user signed in with CognitoUserPools
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent
    ///   with Cognito User Pools auth for authenticated users in the “Admins” group.
    func testGroupPrivateUserPoolsIAM() async {
        let testId = UUID().uuidString
        await setup(withModels: GroupPrivateUserPoolsIAMModels(), testType: .multiAuth, testId: testId)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.amazonCognitoUserPools])
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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
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
        let testId = UUID().uuidString
        await setup(withModels: GroupPublicUserPoolsAPIModels(), testType: .multiAuth, testId: testId)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.amazonCognitoUserPools])
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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API Key
    func testGroupPublicUserPoolsAPIKeyUnauthenticatedUsers() async {
        let testId = UUID().uuidString
        await setup(withModels: GroupPublicUserPoolsAPIModels(), testType: .multiAuth, testId: testId)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.apiKey])
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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
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
        let testId = UUID().uuidString
        await setup(withModels: GroupPublicUserPoolsIAMModels(), testType: .multiAuth, testId: testId)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.amazonCognitoUserPools])
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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with IAM
    func testGroupPublicUserPoolsIAMUnauthenticatedUsers() async {
        let testId = UUID().uuidString
        await setup(withModels: GroupPublicUserPoolsIAMModels(), testType: .multiAuth, testId: testId)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.awsIAM])
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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
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
        let testId = UUID().uuidString
        await setup(withModels: PrivateUserPoolsIAMModels(), testType: .multiAuth, testId: testId)
        await signIn(user: user1)

        let expectations = makeExpectations()
        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.amazonCognitoUserPools])
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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
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
        let testId = UUID().uuidString
        await setup(withModels: PrivatePublicUserPoolsAPIModels(), testType: .multiAuth, testId: testId)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.amazonCognitoUserPools])
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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API key
    func testPrivatePublicUserPoolsAPIKeyUnauthenticatedUsers() async {
        let testId = UUID().uuidString
        await setup(withModels: PrivatePublicUserPoolsAPIModels(), testType: .multiAuth, testId: testId)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.apiKey])
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

        await fulfillment(of: [authTypeExpecation], timeout: 5)

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
        let testId = UUID().uuidString
        await setup(withModels: PrivatePublicUserPoolsIAMModels(), testType: .multiAuth, testId: testId)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.amazonCognitoUserPools])
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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with IAM
    func testPrivatePublicUserPoolsIAMUnauthenticatedUsers() async {
        let testId = UUID().uuidString
        await setup(withModels: PrivatePublicUserPoolsIAMModels(), testType: .multiAuth, testId: testId)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.awsIAM])
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

        await fulfillment(of: [authTypeExpecation], timeout: 5)
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
        let testId = UUID().uuidString
        await setup(withModels: PrivatePublicIAMAPIModels(), testType: .multiAuth, testId: testId)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        let authTypeExpecation = assertUsedAuthTypes(testId: testId, authTypes: [.awsIAM])
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

        await fulfillment(of: [authTypeExpecation], timeout: 5)

    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with API Key
    func testPrivatePublicIAMAPIKeyUnauthenticatedUsers() async {
        let testId = UUID().uuidString

        await setup(withModels: PrivatePublicIAMAPIModels(), testType: .multiAuth, testId: testId)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)
        let authTypeExpectations =  assertUsedAuthTypes(testId: testId, authTypes: [.apiKey])
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

        await fulfillment(of: [authTypeExpectations], timeout: 5)
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests are sent with IAM
    ///   for unauthenticated users
    func testPublicPublicAPIKeyIAMUnauthenticatedUsers() async {
        let testId = UUID().uuidString
        await setup(withModels: PublicPublicAPIIAMModels(), testType: .multiAuth, testId: testId)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)


        let authTypeExpectation = assertUsedAuthTypes(testId: testId, authTypes: [.awsIAM])

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

        await fulfillment(of: [authTypeExpectation], timeout: 5)
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
