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

class AWSDataStoreMultiAuthCombinationTests: AWSDataStoreAuthBaseTest {

    /// Given: an unauthenticated user
    /// When: DataStore start is called
    /// Then: DataStore is successfully initialized.
    func testDataStoreReadyState() async {
        await setup(withModels: PrivatePublicComboModels(),
              testType: .multiAuth)
        await signIn(user: user1)

        let expectations = makeExpectations()
        let startExpectation = expectation(description: "DataStore start success")

        await assertDataStoreReady(expectations)

        // manually start DataStore as we won't trigger any operation
        Task {
            do {
                try await Amplify.DataStore.start()
                await startExpectation.fulfill()
            } catch(let error) {
                XCTFail("DataStore start failure \(error)")
            }
        }

        // we're only interested in "ready-state" expectations
        await expectations.query.fulfill()
        await expectations.mutationSave.fulfill()
        await expectations.mutationSaveProcessed.fulfill()
        await expectations.mutationDelete.fulfill()
        await expectations.mutationDeleteProcessed.fulfill()

        wait(for: [
                startExpectation,
                expectations.query,
                expectations.mutationSave,
                expectations.mutationSaveProcessed,
                expectations.mutationDelete,
                expectations.mutationDeleteProcessed], timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: a user signed in with IAM
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests f
    ///   or PrivatePublicComboUPPost are sent with IAM auth for authenticated users.
    func testOperationsForPrivatePublicComboUPPost() async {
        await setup(withModels: PrivatePublicComboModels(),
              testType: .multiAuth)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: PrivatePublicComboUPPost.self,
                           expectations, onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: PrivatePublicComboUPPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        assertUsedAuthTypes([.apiKey, .amazonCognitoUserPools])
    }

    /// Given: a user signed in with API key
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests
    ///   for PrivatePublicComboAPIPost are sent with API key auth for authenticated users.
    func testOperationsForPrivatePublicComboAPIPostAuthenticatedUser() async {
        await setup(withModels: PrivatePublicComboModels(),
              testType: .multiAuth)
        await signIn(user: user1)

        let expectations = makeExpectations()

        await assertDataStoreReady(expectations)

        // Query
        await assertQuerySuccess(modelType: PrivatePublicComboAPIPost.self,
                           expectations, onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: PrivatePublicComboAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }
        assertUsedAuthTypes([.amazonCognitoUserPools, .apiKey])
    }

    /// Given: an unauthenticated user
    /// When: DataStore query/mutation operations are sent
    /// Then:
    /// - DataStore is successfully initialized, sync/mutation/subscription network requests
    ///   for PrivatePublicComboAPIPost are sent with API key auth for unauthenticated users.
    ///
    ///   PrivatePublicComboUPPost does not sync for unauthenticated users, but it does not block the other models
    ///   from syncing and DataStore getting to a “ready” state.
    func testOperationsForPrivatePublicComboAPIPost() async {
        await setup(withModels: PrivatePublicComboModels(),
              testType: .multiAuth)

        let expectations = makeExpectations()

        // PrivatePublicComboUPPost won't sync for unauthenticated users
        await assertDataStoreReady(expectations, expectedModelSynced: 1)

        // Query
        await assertQuerySuccess(modelType: PrivatePublicComboAPIPost.self,
                           expectations, onFailure: { error in
            XCTFail("Error query \(error)")
        })

        // Mutation
        await assertMutations(model: PrivatePublicComboAPIPost(name: "name"),
                        expectations) { error in
            XCTFail("Error mutation \(error)")
        }
        assertUsedAuthTypes([.apiKey])
    }
}

extension AWSDataStoreMultiAuthCombinationTests {
    struct PrivatePublicComboModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PrivatePublicComboUPPost.self)
            ModelRegistry.register(modelType: PrivatePublicComboAPIPost.self)
        }
    }
}
