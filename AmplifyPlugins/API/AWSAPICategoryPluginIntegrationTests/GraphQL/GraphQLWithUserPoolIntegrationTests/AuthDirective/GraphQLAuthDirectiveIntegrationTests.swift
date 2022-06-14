//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore
import AWSAPICategoryPlugin

@testable import Amplify
@testable import AWSAPICategoryPluginTestCommon
@testable import AmplifyTestCommon

class GraphQLAuthDirectiveIntegrationTests: XCTestCase {
    struct User {
        let username: String
        let password: String
    }

    let amplifyConfigurationFile = "testconfiguration/GraphQLAuthDirectiveIntegrationTests-amplifyconfiguration"
    let credentialsFile = "testconfiguration/GraphQLAuthDirectiveIntegrationTests-credentials"
    var user1: User!
    var user2: User!

    override func setUp() async throws {
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

            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: amplifyConfigurationFile)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: SocialNote.self)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
        if isSignedIn() {
            signOut()
        }
    }

    override func tearDown() async throws {
        signOut()
        await Amplify.reset()
    }

    /// Models created with:
    /// @auth(rules: [ { allow: owner, operations: [create, update, delete] } ])
    ///
    /// Yields the following permissions model:
    ///         Create  Read    Update  Delete
    /// Owner   allow   allow   allow   allow
    /// Others   x      allow   deny    deny
    ///
    /// This creates a read-only model. 'Owner' refers to the user that creates the instance of the model. 'Other'
    /// refers to any other user that was not the owner.
    ///
    /// - When:
    ///    - Model restricts access to create, update, delete.
    /// - Then:
    ///    - Owner can create and update the model
    ///    - Others can read the owner's model
    ///    - Others cannot update or delete the owner's model
    ///    - Owner can delete the model
    func testModelIsReadOnly() {
        signIn(username: user1.username, password: user1.password)
        let id = UUID().uuidString
        let content = "owner created content"
        let ownerCreatedNoteResult = createNote(id, content: content)
        guard case let .success(ownerCreatedNote) = ownerCreatedNoteResult else {
            XCTFail("Owner should be able to successfully create a note")
            return
        }
        let ownerReadNoteResult = queryNote(byId: ownerCreatedNote.model.id)
        guard case let .success(ownerReadNoteOptional) = ownerReadNoteResult,
            let ownerReadNote = ownerReadNoteOptional else {
            XCTFail("Owner should be able to query for own note")
            return
        }
        let ownerUpdateNote = SocialNote(id: ownerReadNote.model.id, content: "owner updated content", owner: nil)
        let ownerUpdatedNoteResult = updateNote(ownerUpdateNote, version: ownerReadNote.syncMetadata.version)
        guard case let .success(ownerUpdatedNote) = ownerUpdatedNoteResult else {
            XCTFail("Owner should be able to update own note")
            return
        }

        signOut()
        signIn(username: user2.username, password: user2.password)
        let otherReadNoteResult = queryNote(byId: id)
        guard case let .success(otherReadNoteOptional) = otherReadNoteResult,
            let otherReadNote = otherReadNoteOptional else {
            XCTFail("Others should be able to read the note")
            return
        }
        let otherUpdateNote = SocialNote(id: otherReadNote.model.id, content: "other updated content", owner: nil)
        let otherUpdatedNoteResult = updateNote(otherUpdateNote, version: otherReadNote.syncMetadata.version)
        guard case let .failure(graphQLResponseErrorOnUpdate) = otherUpdatedNoteResult,
            let appSyncErrorOnUpdate = getAppSyncError(graphQLResponseErrorOnUpdate) else {
            XCTFail("Other should not be able to update owner's note")
            return
        }
        XCTAssertEqual(appSyncErrorOnUpdate, .conditionalCheck)

        let otherDeletedNoteResult = deleteNote(byId: id, version: otherReadNote.syncMetadata.version)
        guard case let .failure(graphQLResponseErrorOnDelete) = otherDeletedNoteResult,
            let appSyncErrorOnDelete = getAppSyncError(graphQLResponseErrorOnDelete) else {
            XCTFail("Other should not be able to delete owner's note")
            return
        }
        XCTAssertEqual(appSyncErrorOnDelete, .conditionalCheck)

        signOut()
        signIn(username: user1.username, password: user1.password)
        let ownerDeletedNoteResult = deleteNote(byId: id, version: ownerUpdatedNote.syncMetadata.version)
        guard case .success = ownerDeletedNoteResult else {
            XCTFail("Owner should be able to delete own note")
            return
        }
    }

    /// An unauthorized user should not be able to make a mutation
    func testUnauthorizedMutation() {
        let failureInvoked = expectation(description: "failure invoked")
        let note = SocialNote(content: "owner created content", owner: nil)
        let request = GraphQLRequest<MutationSyncResult>.createMutation(of: note)
        _ = Amplify.API.mutate(request: request, listener: { event in
            switch event {
            case .success:
                XCTFail("Should not have completed successfully")
            case .failure(let error):
                self.assertNotAuthenticated(error)
                failureInvoked.fulfill()
            }
        })

        wait(for: [failureInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testSyncQuery() {
        signIn(username: user1.username, password: user1.password)
        let id = UUID().uuidString
        let content = "owner created content"
        let ownerCreatedNoteResult = createNote(id, content: content)
        guard case .success = ownerCreatedNoteResult else {
            XCTFail("Owner should be able to successfully create a note")
            return
        }

        let syncQueryResult = syncQuery()
        guard case .success = syncQueryResult else {
            XCTFail("Owner should be able to execute sync query")
            return
        }
    }

    /// An unauthorized user should not be able to query
    func testUnauthorizedSyncQuery() {
        let failureInvoked = expectation(description: "failure invoked")
        let request = GraphQLRequest<SyncQueryResult>.syncQuery(modelType: SocialNote.self, limit: 1)
        _ = Amplify.API.query(request: request) { event in
            switch event {
            case .success:
                XCTFail("Should not have completed successfully")
            case .failure(let error):
                self.assertNotAuthenticated(error)
                failureInvoked.fulfill()
            }
        }
        wait(for: [failureInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testOnCreateSubscriptionOnlyWhenSignedIntoUserPool() {
        signIn(username: user1.username, password: user1.password)
        let connectedInvoked = expectation(description: "Connection established")
        let progressInvoked = expectation(description: "Progress invoked")
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: SocialNote.self,
                                                                      subscriptionType: .onCreate)
        let operation = Amplify.API.subscribe(
            request: request,
            valueListener: { graphQLResponse in
                switch graphQLResponse {
                case .connection(let state):
                    if case .connected = state {
                        connectedInvoked.fulfill()
                    }
                case .data(let graphQLResponse):
                    switch graphQLResponse {
                    case .success:
                        progressInvoked.fulfill()
                    case .failure(let error):
                        XCTFail(error.errorDescription)
                    }
                }
        }, completionListener: { result in
            switch result {
            case .failure(let error):
                XCTFail("Unexpected .failed event: \(error)")
            case .success:
                break
            }
        })
        wait(for: [connectedInvoked], timeout: TestCommonConstants.networkTimeout)

        let ownerCreatedNoteResult = createNote(content: "owner created content")
        guard case .success = ownerCreatedNoteResult else {
            XCTFail("Owner should be able to successfully create a note")
            return
        }

        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        operation.cancel()
    }
}
