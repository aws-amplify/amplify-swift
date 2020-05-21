//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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
            try Amplify.add(plugin: AWSAuthPlugin())
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
        signOut()
        Amplify.reset()
    }

    /// A user can persist data in the local store without signing in. Once the user signs in,
    /// the sync engine will start and sync the mutations to the cloud. Once the reconcillation is complete, retrieving
    /// the same data will contain ownerId
    ///
    /// - Given: A DataStore plugin configured with SocialNote model containing with auth rules
    /// - When:
    ///    - User is not signed in, then user can successfully save a note to local store
    ///    - User remains signed out, then user can successfully retrieve the saved note, with empty owner field
    ///    - User signs in, then the sync engine is started and reconciles local store with the ownerId
    ///    - User retrieves the note again and now it contains the ownerId
    ///    - User signs out, the local store is cleared, then retrieving note returns nil
    func testUnauthenticatedSavesToLocalStoreIsReconciledWithCloudStoreAfterAuthentication() throws {
        // 1
        let id = UUID().uuidString
        let note = SocialNote(id: id, content: "owner created content", owner: nil)
        let savedNoteInvoked = expectation(description: "note was saved")
        Amplify.DataStore.save(note) { result in
            switch result {
            case .success(let note):
                print(note)
                savedNoteInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed to save note \(error)")
            }
        }
        wait(for: [savedNoteInvoked], timeout: TestCommonConstants.networkTimeout)

        // 2
        let queriedNoteInvoked = expectation(description: "note was queried")
        Amplify.DataStore.query(SocialNote.self, byId: id) { result in
            switch result {
            case .success(let socialNoteOptional):
                guard let note = socialNoteOptional else {
                    XCTFail("Failed to query note")
                    return
                }
                print(note)
                XCTAssertNil(note.owner)
                queriedNoteInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed to save note \(error)")
            }
        }
        wait(for: [queriedNoteInvoked], timeout: TestCommonConstants.networkTimeout)

        // 3
        let syncStarted = expectation(description: "Sync started after sign In")
        var token: UnsubscribeToken!
        token = Amplify.Hub.listen(to: .dataStore,
                                   eventName: HubPayload.EventName.DataStore.syncStarted) { _ in
                                    syncStarted.fulfill()
                                    Amplify.Hub.removeListener(token)

        }

        guard try HubListenerTestUtilities.waitForListener(with: token, timeout: 10.0) else {
            XCTFail("Hub Listener not registered")
            return
        }

        signIn(username: user1.username, password: user1.password)
        wait(for: [syncStarted], timeout: TestCommonConstants.networkTimeout)
    }

    /// A signed in user (the owner) creates some data in local store will be synced to cloud. After signing out,
    /// the data can no longer be retrieved. Signing back in with another user will update the local store with all
    /// the data that can be read by that the user in the sync process. Then other user can read the owner's data.
    ///
    /// - Given: A DataStore plugin configured with auth enabled SocialNote model that can be read others.
    /// - When:
    ///    - The owner user is signed in, then user can save a note successfully
    ///    - Owner signs out, then retrieving the note returns nil
    ///    - The other user signs in, sync engine is started and does a full sync
    ///    - The other user is able to retrieve the owner's note
    func testOwnerCreatedDataCanBeReadByOtherUsersForReadableModel() {
        
    }
}
