//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSMobileClient
import AWSAPICategoryPlugin
@testable import AWSAPICategoryPluginTestCommon
@testable import AmplifyTestCommon
import AWSPluginsCore

class GraphQLAuthDirectiveIntegrationTests: XCTestCase {

    static let amplifyConfiguration = "GraphQLAuthDirectiveIntegrationTests-amplifyconfiguration"
    static let awsconfiguration = "GraphQLAuthDirectiveIntegrationTests-awsconfiguration"
    static let credentials = "GraphQLAuthDirectiveIntegrationTests-credentials"
    static var user1: String!
    static var user2: String!
    static var password: String!

    static override func setUp() {
        do {

            let credentials = try TestConfigHelper.retrieveCredentials(
                forResource: GraphQLAuthDirectiveIntegrationTests.credentials)

            guard let user1 = credentials["user1"],
                let user2 = credentials["user2"],
                let password = credentials["password"] else {
                    XCTFail("Missing credentials.json data")
                    return
            }

            GraphQLAuthDirectiveIntegrationTests.user1 = user1
            GraphQLAuthDirectiveIntegrationTests.user2 = user2
            GraphQLAuthDirectiveIntegrationTests.password = password

            let awsConfiguration = try TestConfigHelper.retrieveAWSConfiguration(
                forResource: GraphQLAuthDirectiveIntegrationTests.awsconfiguration)
            AWSInfo.configureDefaultAWSInfo(awsConfiguration)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func setUp() {
        do {
            AuthHelper.initializeMobileClient()

            Amplify.reset()

            try Amplify.add(plugin: AWSAPIPlugin())

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLAuthDirectiveIntegrationTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: SocialNote.self)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
        AuthHelper.signOut()
    }

    /// A model with operations [create, update, delete] allows the model to be read by others but not updated or
    /// deleted. This creates a read-only model.
    ///
    /// - When:
    ///    - Model restricts access to create, update, delete.
    /// - Then:
    ///    - Owner can create and update the model
    ///    - Others can read the owner's model
    ///    - Others cannot update or delete the owner's model
    ///    - Owner can delete the model
    func testModelIsReadOnly() {
        AuthHelper.signIn(username: GraphQLAuthDirectiveIntegrationTests.user1,
                          password: GraphQLAuthDirectiveIntegrationTests.password)
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
        AuthHelper.signOut()
        AuthHelper.signIn(username: GraphQLAuthDirectiveIntegrationTests.user2,
                          password: GraphQLAuthDirectiveIntegrationTests.password)
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

        AuthHelper.signOut()
        AuthHelper.signIn(username: GraphQLAuthDirectiveIntegrationTests.user1,
                          password: GraphQLAuthDirectiveIntegrationTests.password)
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
            case .completed:
                XCTFail("Should not have completed successfully")
            case .failed(let error):
                self.assertNotAuthenticated(error)
                failureInvoked.fulfill()
            default:
                XCTFail("Unexpected case")
            }
        })

        wait(for: [failureInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testSyncQuery() {
        AuthHelper.signIn(username: GraphQLAuthDirectiveIntegrationTests.user1,
                          password: GraphQLAuthDirectiveIntegrationTests.password)
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
            case .completed:
                XCTFail("Should not have completed successfully")
            case .failed(let error):
                self.assertNotAuthenticated(error)
                failureInvoked.fulfill()
            default:
                XCTFail("Unexpected case")
            }
        }
        wait(for: [failureInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testOnCreateSubscriptionOnlyWhenSignedIntoUserPool() {
        AuthHelper.signIn(username: GraphQLAuthDirectiveIntegrationTests.user1,
                          password: GraphQLAuthDirectiveIntegrationTests.password)
        let connectedInvoked = expectation(description: "Connection established")
        let progressInvoked = expectation(description: "Progress invoked")
        guard let ownerId = AuthHelper.getUserSub() else {
            XCTFail("Could not get ownerId for authenticated user")
            return
        }
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: SocialNote.self,
                                                                      subscriptionType: .onCreate,
                                                                      ownerId: ownerId)
        let operation = Amplify.API.subscribe(request: request) { event in
            switch event {
            case .inProcess(let graphQLResponse):
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
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            case .completed:
                break
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
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
