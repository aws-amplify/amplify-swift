//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AmplifyPlugins
import AWSDataStoreCategoryPlugin

@testable import Amplify
@testable import AmplifyTestCommon

class AWSDataStoreCategoryPluginAuthIntegrationTests: XCTestCase {

    struct User {
        let username: String
        let password: String
    }

    let amplifyConfigurationFile = "AWSDataStoreCategoryPluginAuthIntegrationTests-amplifyconfiguration"
    let credentialsFile = "AWSDataStoreCategoryPluginAuthIntegrationTests-credentials"
    var user1: User!
    var user2: User!

    let syncReceived = HubPayload.EventName.DataStore.syncReceived
    let syncStarted = HubPayload.EventName.DataStore.syncStarted

    override func setUp() {
        Amplify.Logging.logLevel = .verbose

        do {
            let credentials = try TestConfigHelper.retrieveCredentials(forResource: credentialsFile)

            guard let user1 = credentials["user1"],
                let user2 = credentials["user2"],
                let passwordUser1 = credentials["passwordUser1"],
                let passwordUser2 = credentials["passwordUser2"] else {
                    XCTFail("Missing credentials.json data")
                    return
            }

            self.user1 = User(username: user1, password: passwordUser1)
            self.user2 = User(username: user2, password: passwordUser2)

            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: SocialNoteModelRegistration()))
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: amplifyConfigurationFile)
            try Amplify.configure(amplifyConfig)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
        if isSignedIn() {
            signOut()
        }
    }

    override func tearDown() {
        let stopped = expectation(description: "stopped")
        Amplify.DataStore.stop { _ in stopped.fulfill() }
        waitForExpectations(timeout: 1.0)

        signOut()
        Amplify.reset()
    }

    /// A user can persist data in the local store without signing in. Once the user signs in,
    /// the sync engine will start and sync the mutations to the cloud. Once the reconciliation is complete, retrieving
    /// the same data will contain ownerId
    ///
    /// - Given: A DataStore plugin configured with SocialNote model containing with auth rules
    /// - When:
    ///    - User is not signed in, then user can successfully save a note to local store
    ///    - User remains signed out, then user can successfully retrieve the saved note, with empty owner field
    ///    - User signs in, retrieves note, sync engine is started and reconciles local store with the ownerId
    ///    - The note now it contains the ownerId
    func testUnauthenticatedSavesToLocalStoreIsReconciledWithCloudStoreAfterAuthentication() throws {
        let savedLocalNote = saveNote(content: "owner saved note")
        let queriedNoteOptional = queryNote(byId: savedLocalNote.id)
        guard let note = queriedNoteOptional else {
            XCTFail("Failed to query local note")
            return
        }
        guard note.owner == nil else {
            XCTFail("Owner field in model is not automatically set on a local DataStore call. It should be empty")
            return
        }

        let syncReceivedInvoked = expectation(description: "Received SyncReceived event")
        var remoteNoteOptional: SocialNote?
        let syncReceivedListener = Amplify.Hub.listen(to: .dataStore, eventName: syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent,
                let note = try? mutationEvent.decodeModel() as? SocialNote else {
                    XCTFail("Can't cast payload as mutation event")
                    return
            }
            if note.id == savedLocalNote.id {
                remoteNoteOptional = note
                syncReceivedInvoked.fulfill()
            }
        }
        guard try HubListenerTestUtilities.waitForListener(with: syncReceivedListener, timeout: 5.0) else {
            XCTFail("syncReceivedListener registered for hub")
            return
        }

        signIn(username: user1.username, password: user1.password)

        wait(for: [syncReceivedInvoked], timeout: TestCommonConstants.networkTimeout)
        Amplify.Hub.removeListener(syncReceivedListener)
        guard let remoteNote = remoteNoteOptional else {
            XCTFail("Should have received a SyncReceived event with the remote note reconciled to local store")
            return
        }
        guard let remoteNoteOwner = remoteNote.owner else {
            XCTFail("The synchronized model from remote should contain the owner field peristed")
            return
        }

        guard let user = Amplify.Auth.getCurrentUser() else {
            XCTFail("Couldn't get current user signed in user")
            return
        }
        XCTAssertEqual(user.username, remoteNoteOwner)
    }

    /// User1, while signed in, creates some data, called "NewUser1Data" in a local store. We wait for this data to be
    /// synced to the cloud and then call `DataStore.clear()` so that data will be destroyed in the local data store and
    /// the remote sync engine will be halted. After this finishes, we sign out of user1 and sign in with user2, which
    /// will restart the sync engine and read all of data from the backend including "NewUser1Data".
    ///
    /// - Given: A DataStore plugin configured with auth enabled SocialNote model that can be read others.
    /// - When:
    ///    - The owner user is signed in, user saves a note, syncReceived successfully
    ///    - Owner signs out, `DataStore.clear`, then retrieving the note returns nil
    ///    - The other user signs in, sync engine is started and does a full sync
    ///    - The other user is able to retrieve the owner's note
    func testOwnerCreatedDataCanBeReadByOtherUsersForReadableModel() throws {
        signIn(username: user1.username, password: user1.password)

        let id = UUID().uuidString
        let localNote = SocialNote(id: id, content: "owner created content", owner: nil)
        let localNoteSaveInvoked = expectation(description: "local note was saved")

        let syncReceivedInvoked = expectation(description: "received SyncReceived event")
        var remoteNoteOptional: SocialNote?
        let syncReceivedListener = Amplify.Hub.listen(to: .dataStore, eventName: syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent,
                let note = try? mutationEvent.decodeModel() as? SocialNote else {
                    XCTFail("Can't cast payload as mutation event")
                    return
            }
            if note.id == localNote.id {
                remoteNoteOptional = note
                syncReceivedInvoked.fulfill()
            }
        }
        guard try HubListenerTestUtilities.waitForListener(with: syncReceivedListener, timeout: 5.0) else {
            XCTFail("syncReceivedListener registered for hub")
            return
        }

        Amplify.DataStore.save(localNote) { result in
            switch result {
            case .success(let note):
                print(note)
                localNoteSaveInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed to save note \(error)")
            }
        }
        wait(for: [localNoteSaveInvoked], timeout: TestCommonConstants.networkTimeout)
        wait(for: [syncReceivedInvoked], timeout: TestCommonConstants.networkTimeout)
        Amplify.Hub.removeListener(syncReceivedListener)
        guard let remoteNote = remoteNoteOptional else {
            XCTFail("Should have received a SyncReceived event with the remote note reconciled to local store")
            return
        }
        guard let owner = remoteNote.owner else {
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

        let localNoteOptional = queryNote(byId: id)
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
        var remoteNoteOptional2: SocialNote?
        let syncReceivedListener2 = Amplify.Hub.listen(to: .dataStore, eventName: syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent,
                let note = try? mutationEvent.decodeModel() as? SocialNote else {
                    XCTFail("Can't cast payload as mutation event")
                    return
            }
            if note.id == localNote.id {
                remoteNoteOptional2 = note
                syncReceivedInvoked2.fulfill()
            }
        }
        guard try HubListenerTestUtilities.waitForListener(with: syncReceivedListener2, timeout: 5.0) else {
            XCTFail("syncReceivedListener2 registered for hub")
            return
        }
        signIn(username: user2.username, password: user2.password)
        guard let currentUser = Amplify.Auth.getCurrentUser() else {
            XCTFail("Could not retrieve current user")
            return
        }
        XCTAssertNotEqual(currentUser.username, owner)
        wait(for: [syncStartedInvoked2], timeout: TestCommonConstants.networkTimeout)
        wait(for: [syncReceivedInvoked2], timeout: TestCommonConstants.networkTimeout)
        Amplify.Hub.removeListener(syncStartedListener2)
        Amplify.Hub.removeListener(syncReceivedListener2)
        guard let ownerRemoteNote = remoteNoteOptional2, let remoteNoteOwner = ownerRemoteNote.owner else {
            XCTFail("Should have received a SyncReceived event with the remote note reconciled to local store")
            return
        }

        XCTAssertEqual(owner, remoteNoteOwner)
    }
}
