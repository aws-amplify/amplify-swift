//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSDataStorePlugin
@testable import Amplify
#if !os(watchOS)
@testable import DataStoreHostApp
#endif

class AWSDataStoreCategoryPluginAuthIntegrationTests: AWSDataStoreAuthBaseTest {
    let syncReceived = HubPayload.EventName.DataStore.syncReceived
    let syncStarted = HubPayload.EventName.DataStore.syncStarted

    /// A user can persist data in the local store without signing in. Once the user signs in,
    /// the sync engine will start and sync the mutations to the cloud. Once the reconciliation is complete, retrieving
    /// the same data will contain ownerId
    ///
    /// - Given: A DataStore plugin configured with SocialNote model containing with auth rules
    /// - When:
    ///    - User is not signed in, then user can successfully save a todo to local store
    ///    - User remains signed out, then user can successfully retrieve the saved todo, with empty owner field
    ///    - User signs in, retrieves tods, sync engine is started and reconciles local store with the ownerId
    ///    - The todo now it contains the ownerId
    func testUnauthenticatedSavesToLocalStoreIsReconciledWithCloudStoreAfterAuthentication() async throws {
        try await setup(withModels: ModelsRegistration(), testType: .defaultAuthCognito)
        let savedLocalTodo = TodoExplicitOwnerField(content: "owner saved model")
        try await saveModel(savedLocalTodo)
        let queriedNoteOptional = try await queryModel(TodoExplicitOwnerField.self, byId: savedLocalTodo.id)
        guard let model = queriedNoteOptional else {
            XCTFail("Failed to query local model")
            return
        }
        guard model.owner == nil else {
            XCTFail("Owner field in model is not automatically set on a local DataStore call. It should be empty")
            return
        }

        let syncReceivedInvoked = asyncExpectation(description: "Received SyncReceived event")
        var remoteTodoOptional: TodoExplicitOwnerField?
        let syncReceivedListener = Amplify.Hub.listen(to: .dataStore, eventName: syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent,
                let todo = try? mutationEvent.decodeModel() as? TodoExplicitOwnerField else {
                    print("Can't cast payload as mutation event")
                    return
            }
            if todo.id == savedLocalTodo.id {
                remoteTodoOptional = todo
                Task { await syncReceivedInvoked.fulfill() }
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: syncReceivedListener, timeout: 5.0) else {
            XCTFail("syncReceivedListener registered for hub")
            return
        }

        try await signIn(user: user1)

        await waitForExpectations([syncReceivedInvoked], timeout: TestCommonConstants.networkTimeout)
        Amplify.Hub.removeListener(syncReceivedListener)
        guard let remoteTodo = remoteTodoOptional else {
            XCTFail("Should have received a SyncReceived event with the remote note reconciled to local store")
            return
        }
        guard let remoteTodoOwner = remoteTodo.owner else {
            XCTFail("The synchronized model from remote should contain the owner field persisted")
            return
        }

        guard let user = try? await Amplify.Auth.getCurrentUser() else {
            XCTFail("Couldn't get current user signed in user")
            return
        }
        XCTAssertEqual(user.username, remoteTodoOwner)
    }

}

extension AWSDataStoreCategoryPluginAuthIntegrationTests {
    private struct ModelsRegistration: AmplifyModelRegistration {
        var version: String = "version"

        public func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: TodoExplicitOwnerField.self)
            ModelRegistry.register(modelType: TodoImplicitOwnerField.self)
          }
    }
}
