//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSDataStorePlugin
@testable import Amplify
@testable import AmplifyTestCommon

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
    func testUnauthenticatedSavesToLocalStoreIsReconciledWithCloudStoreAfterAuthentication() throws {
        setup(withModels: ModelsRegistration(), testType: .defaultAuthCognito)
        let savedLocalTodo = TodoExplicitOwnerField(content: "owner saved model")
        saveModel(savedLocalTodo)
        let queriedNoteOptional = queryModel(TodoExplicitOwnerField.self, byId: savedLocalTodo.id)
        guard let model = queriedNoteOptional else {
            XCTFail("Failed to query local model")
            return
        }
        guard model.owner == nil else {
            XCTFail("Owner field in model is not automatically set on a local DataStore call. It should be empty")
            return
        }

        let syncReceivedInvoked = expectation(description: "Received SyncReceived event")
        var remoteTodoOptional: TodoExplicitOwnerField?
        let syncReceivedListener = Amplify.Hub.listen(to: .dataStore, eventName: syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent,
                let todo = try? mutationEvent.decodeModel() as? TodoExplicitOwnerField else {
                    XCTFail("Can't cast payload as mutation event")
                    return
            }
            if todo.id == savedLocalTodo.id {
                remoteTodoOptional = todo
                syncReceivedInvoked.fulfill()
            }
        }
        guard try HubListenerTestUtilities.waitForListener(with: syncReceivedListener, timeout: 5.0) else {
            XCTFail("syncReceivedListener registered for hub")
            return
        }

        signIn(user: user1)

        wait(for: [syncReceivedInvoked], timeout: TestCommonConstants.networkTimeout)
        Amplify.Hub.removeListener(syncReceivedListener)
        guard let remoteTodo = remoteTodoOptional else {
            XCTFail("Should have received a SyncReceived event with the remote note reconciled to local store")
            return
        }
        guard let remoteTodoOwner = remoteTodo.owner else {
            XCTFail("The synchronized model from remote should contain the owner field persisted")
            return
        }

        guard let user = Amplify.Auth.getCurrentUser() else {
            XCTFail("Couldn't get current user signed in user")
            return
        }
        XCTAssertEqual(user.username, remoteTodoOwner)
    }

    /// User1, while signed in, creates some data, called "NewUser1Data" in a local store. We wait for this data to be
    /// synced to the cloud and then call `DataStore.clear()` so that data will be destroyed in the local data store and
    /// the remote sync engine will be halted. After this finishes, we sign out of user1 and sign in with user2, which
    /// will restart the sync engine and read all of data from the backend including "NewUser1Data".
    ///
    /// - Given: A DataStore plugin configured with auth enabled TodoExplicitOwnerField model that can be read others.
    /// - When:
    ///    - The owner user is signed in, user saves a todo, syncReceived successfully
    ///    - Owner signs out, `DataStore.clear`, then retrieving the todo returns nil
    ///    - The other user signs in, sync engine is started and does a full sync
    ///    - The other user is able to retrieve the owner's todo
    func testOwnerCreatedDataCanBeReadByOtherUsersForReadableModel() throws {
        setup(withModels: ModelsRegistration(), testType: .defaultAuthCognito)

        signIn(user: user1)

        let id = UUID().uuidString
        let localTodo = TodoExplicitOwnerField(id: id, content: "owner created content", owner: nil)
        let localTodoSaveInvoked = expectation(description: "local note was saved")

        let syncReceivedInvoked = expectation(description: "received SyncReceived event")
        var remoteTodoOptional: TodoExplicitOwnerField?
        let syncReceivedListener = Amplify.Hub.listen(to: .dataStore, eventName: syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent,
                let todo = try? mutationEvent.decodeModel() as? TodoExplicitOwnerField else {
                    XCTFail("Can't cast payload as mutation event")
                    return
            }
            if todo.id == localTodo.id, remoteTodoOptional == nil {
                remoteTodoOptional = todo
                syncReceivedInvoked.fulfill()
            }
        }
        guard try HubListenerTestUtilities.waitForListener(with: syncReceivedListener, timeout: 5.0) else {
            XCTFail("syncReceivedListener registered for hub")
            return
        }

        Amplify.DataStore.save(localTodo) { result in
            switch result {
            case .success(let note):
                localTodoSaveInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed to save note \(error)")
            }
        }
        wait(for: [localTodoSaveInvoked], timeout: TestCommonConstants.networkTimeout)
        wait(for: [syncReceivedInvoked], timeout: TestCommonConstants.networkTimeout)
        guard let remoteTodo = remoteTodoOptional else {
            XCTFail("Should have received a SyncReceived event with the remote note reconciled to local store")
            return
        }
        guard let owner = remoteTodo.owner else {
            XCTFail("Could not retrieve owner value from remote note")
            return
        }

        signOut()

        let clearCompletedInvoked = expectation(description: "clear completed")
        Amplify.DataStore.clear { result in
            switch result {
            case .success:
                clearCompletedInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed to clear \(error)")
            }
        }

        wait(for: [clearCompletedInvoked], timeout: TestCommonConstants.networkTimeout)

        let modelSyncedInvoked = expectation(description: "Model fully synced")
        Amplify
            .Hub
            .publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.ready }
            .sink { _ in
                modelSyncedInvoked.fulfill()
            }.store(in: &requests)

        let localNoteOptional = queryModel(TodoExplicitOwnerField.self, byId: id)
        XCTAssertNil(localNoteOptional)

        let syncStartedInvoked2 = expectation(description: "Sync started after other sign in")
        let syncStartedListener2 = Amplify.Hub.listen(to: .dataStore, eventName: syncStarted) { _ in
            syncStartedInvoked2.fulfill()
        }
        guard try HubListenerTestUtilities.waitForListener(with: syncStartedListener2, timeout: 5.0) else {
            XCTFail("syncStartedListener2 not registered")
            return
        }

        let syncReceivedInvoked2 = expectation(description: "received SyncReceived event for owner")
        var remoteNoteOptional2: TodoExplicitOwnerField?
        let syncReceivedListener2 = Amplify.Hub.listen(to: .dataStore, eventName: syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent,
                let note = try? mutationEvent.decodeModel() as? TodoExplicitOwnerField else {
                    XCTFail("Can't cast payload as mutation event")
                    return
            }
            if note.id == localTodo.id {
                remoteNoteOptional2 = note
                syncReceivedInvoked2.fulfill()
            }
        }
        guard try HubListenerTestUtilities.waitForListener(with: syncReceivedListener2, timeout: 5.0) else {
            XCTFail("syncReceivedListener2 registered for hub")
            return
        }
        signIn(user: user2)
        guard let currentUser = Amplify.Auth.getCurrentUser() else {
            XCTFail("Could not retrieve current user")
            return
        }
        XCTAssertNotEqual(currentUser.username, owner)
        wait(for: [syncStartedInvoked2], timeout: TestCommonConstants.networkTimeout)
        wait(for: [syncReceivedInvoked2], timeout: TestCommonConstants.networkTimeout)
        guard let ownerRemoteNote = remoteNoteOptional2, let remoteNoteOwner = ownerRemoteNote.owner else {
            XCTFail("Should have received a SyncReceived event with the remote note reconciled to local store")
            return
        }

        XCTAssertEqual(owner, remoteNoteOwner)
        wait(for: [modelSyncedInvoked], timeout: TestCommonConstants.networkTimeout)
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
