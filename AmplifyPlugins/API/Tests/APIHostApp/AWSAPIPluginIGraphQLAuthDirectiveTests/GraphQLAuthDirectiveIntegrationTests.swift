//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore
import AWSAPIPlugin
import AWSCognitoAuthPlugin

@testable import Amplify
@testable import APIHostApp

class GraphQLAuthDirectiveIntegrationTests: XCTestCase {
    struct User {
        let username: String
        let password: String
    }
    
    let amplifyConfigurationFile = "testconfiguration/GraphQLWithUserPoolIntegrationTests-amplifyconfiguration"
    var user1: User!
    var user2: User!
    
    override func setUp() async throws {
        do {
            user1 = User(username: "integTest\(UUID().uuidString)", password: "P123@\(UUID().uuidString)")
            user2 = User(username: "integTest\(UUID().uuidString)", password: "P123@\(UUID().uuidString)")
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: amplifyConfigurationFile)
            try Amplify.configure(amplifyConfig)
            
            _ = try await AuthSignInHelper.signUpUser(username: user1.username,
                                                      password: user1.password,
                                                      email: "\(user1.username)@\(UUID().uuidString).com")
            _ = try await AuthSignInHelper.signUpUser(username: user2.username,
                                                      password: user2.password,
                                                      email: "\(user2.username)@\(UUID().uuidString).com")
            ModelRegistry.register(modelType: SocialNote.self)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
        if try await isSignedIn() {
            await signOut()
        }
    }
    
    override func tearDown() async throws {
        await signOut()
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
    func testModelIsReadOnly() async throws {
        try await signIn(username: user1.username, password: user1.password)
        let id = UUID().uuidString
        let content = "owner created content"
        do {
            let ownerCreatedNoteResult = try await createNote(id, content: content)
            guard case let .success(ownerCreatedNote) = ownerCreatedNoteResult else {
                XCTFail("Owner should be able to successfully create a note")
                return
            }
            
            let ownerReadNoteResult = try await queryNote(byId: ownerCreatedNote.model.id)
            guard case let .success(ownerReadNoteOptional) = ownerReadNoteResult,
                  let ownerReadNote = ownerReadNoteOptional else {
                XCTFail("Owner should be able to query for own note")
                return
            }
            
            let ownerUpdateNote = SocialNote(id: ownerReadNote.model.id, content: "owner updated content", owner: nil)
            let ownerUpdatedNoteResult = try await updateNote(ownerUpdateNote, version: ownerReadNote.syncMetadata.version)
            guard case let .success(ownerUpdatedNote) = ownerUpdatedNoteResult else {
                XCTFail("Owner should be able to update own note")
                return
            }
            await signOut()
            
            try await signIn(username: user2.username, password: user2.password)
            let otherReadNoteResult = try await queryNote(byId: id)
            guard case let .success(otherReadNoteOptional) = otherReadNoteResult,
                  let otherReadNote = otherReadNoteOptional else {
                XCTFail("Others should be able to read the note")
                return
            }
            
            let otherUpdateNote = SocialNote(id: otherReadNote.model.id, content: "other updated content", owner: nil)
            do {
                let otherUpdatedNoteResult = try await updateNote(otherUpdateNote, version: otherReadNote.syncMetadata.version)
                guard case let .failure(graphQLResponseErrorOnUpdate) = otherUpdatedNoteResult,
                      let appSyncErrorOnUpdate = getAppSyncError(graphQLResponseErrorOnUpdate) else {
                    XCTFail("Other should not be able to update owner's note")
                    return
                }
                XCTAssertEqual(appSyncErrorOnUpdate, .conditionalCheck)
            } catch (let error) {
                XCTFail("Failed with error: \(error)")
            }
            
            await signOut()
            try await signIn(username: user1.username, password: user1.password)
            do {
                let result = try await deleteNote(byId: id, version: ownerUpdatedNote.syncMetadata.version)
                XCTAssertNotNil(result)
            } catch(let error) {
                XCTFail("Owner should be able to delete own note: \(error)")
            }
        } catch (let error as APIError) {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// An unauthorized user should not be able to make a mutation
    func testUnauthorizedMutation() async throws {
        let failureInvoked = expectation(description: "failure invoked")
        let note = SocialNote(content: "owner created content", owner: nil)
        let request = GraphQLRequest<MutationSyncResult>.createMutation(of: note)
        do {
            _ = try await Amplify.API.mutate(request: request)
            XCTFail("Should not have completed successfully")
        } catch (let error as APIError) {
            self.assertNotAuthenticated(error)
            failureInvoked.fulfill()
        }
        wait(for: [failureInvoked], timeout: TestCommonConstants.networkTimeout)
    }
    
    func testSyncQuery() async throws {
        try await signIn(username: user1.username, password: user1.password)
        let id = UUID().uuidString
        let content = "owner created content"
        do {
            _ = try await createNote(id, content: content)
            _ = try await syncQuery()
        } catch (let error as APIError) {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// An unauthorized user should not be able to query
    func testUnauthorizedSyncQuery() async throws {
        let failureInvoked = asyncExpectation(description: "failure invoked")
        let request = GraphQLRequest<SyncQueryResult>.syncQuery(modelType: SocialNote.self, limit: 1)
        do {
            _ = try await Amplify.API.query(request: request)
            XCTFail("Should not have completed successfully")
        } catch (let error as APIError){
            self.assertNotAuthenticated(error)
            await failureInvoked.fulfill()
        }
        
        await waitForExpectations([failureInvoked], timeout: TestCommonConstants.networkTimeout)
    }
    
    func testOnCreateSubscriptionOnlyWhenSignedIntoUserPool() async throws {
        try await signIn(username: user1.username, password: user1.password)
        let connectedInvoked = asyncExpectation(description: "Connection established")
        let progressInvoked = asyncExpectation(description: "Progress invoked")
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: SocialNote.self,
                                                                      subscriptionType: .onCreate)
        let subscription = Amplify.API.subscribe(request: request)
        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(let state):
                        if case .connected = state {
                            await connectedInvoked.fulfill()
                        }
                    case .data(let graphQLResponse):
                        switch graphQLResponse {
                        case .success:
                            await progressInvoked.fulfill()
                        case .failure(let error):
                            XCTFail(error.errorDescription)
                        }
                    }
                }
            } catch (let error as APIError) {
                XCTFail("Unexpected subscription failure: \(error)")
            }
        }
        
        await waitForExpectations([connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        
        do {
            _ = try await createNote(content: "owner created content")
        } catch (let error) {
            XCTFail("Owner should be able to successfully create a note: \(error)")
        }
        
        await waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)
        subscription.cancel()
    }
    
    
    // MARK: - Helpers
    
    func signIn(username: String, password: String) async throws {
        do {
            let signInResult = try await Amplify.Auth.signIn(username: username, password: password)
            guard signInResult.isSignedIn else {
                XCTFail("Sign in successful but not complete")
                return
            }
        } catch (let error) {
            XCTFail("Failed with signIn error: \(error)")
        }
    }
    
    func signOut() async {
        _ = await Amplify.Auth.signOut()
    }
    
    func isSignedIn() async throws -> Bool {
        let authSession = try await Amplify.Auth.fetchAuthSession()
        return authSession.isSignedIn
    }
    
    func createNote(_ id: String = UUID().uuidString, content: String) async throws -> GraphQLResponse<MutationSyncResult> {
        let note = SocialNote(id: id, content: content, owner: nil)
        let request = GraphQLRequest<MutationSyncResult>.createMutation(of: note)
        let mutateResult = try await Amplify.API.mutate(request: request)
        return mutateResult
    }
    
    func updateNote(_ note: SocialNote, version: Int) async throws -> GraphQLResponse<MutationSyncResult> {
        let request = GraphQLRequest<MutationSyncResult>.updateMutation(of: note, version: version)
        let mutateResult = try await Amplify.API.mutate(request: request)
        return mutateResult
    }
    
    func deleteNote(byId id: String, version: Int) async throws -> GraphQLResponse<MutationSyncResult> {
        let request = GraphQLRequest<MutationSyncResult>.deleteMutation(of: SocialNote(id: id, content: ""),
                                                                        modelSchema: SocialNote.schema,
                                                                        version: version)
        let mutateResult = try await Amplify.API.mutate(request: request)
        return mutateResult
    }
    
    func queryNote(byId id: String) async throws -> GraphQLResponse<MutationSyncResult?> {
        let request = GraphQLRequest<MutationSyncResult?>.query(modelName: SocialNote.modelName, byId: id)
        let queryResult = try await Amplify.API.query(request: request)
        return queryResult
    }
    
    func syncQuery() async throws -> SyncQueryResult {
        let syncQueryInvoked = asyncExpectation(description: "note was sync queried")
        var resultOptional: SyncQueryResult?
        let request = GraphQLRequest<SyncQueryResult>.syncQuery(modelType: SocialNote.self, limit: 1)
        let queryResult = try await Amplify.API.query(request: request)
        switch queryResult {
        case .success(let data):
            resultOptional = data
            await syncQueryInvoked.fulfill()
        case .failure(let error):
            XCTFail("Got failed, error: \(error)")
        }
        await waitForExpectations([syncQueryInvoked], timeout: TestCommonConstants.networkTimeout)
        guard let result = resultOptional else {
            fatalError("Failed to sync query note")
        }
        return result
    }
    
    func getAppSyncError(_ graphQLResponseError: GraphQLResponseError<MutationSyncResult>) -> AppSyncErrorType? {
        guard case let .error(errors) = graphQLResponseError,
              let error = errors.first,
              let extensions = error.extensions,
              case let .string(errorTypeValue) = extensions["errorType"] else {
            XCTFail("Missing expected `errorType` from error.extensions")
            return nil
        }
        return AppSyncErrorType(errorTypeValue)
    }
    
    func assertNotAuthenticated(_ error: APIError) {
        guard case let .operationError(_, _, underlyingError) = error else {
            XCTFail("Error should be operationError")
            return
        }
        guard let authError = underlyingError as? AuthError else {
            XCTFail("underlying error should be AuthError, but instead was \(underlyingError ?? "nil")")
            return
        }
        guard case .signedOut = authError else {
            XCTFail("Error should be AuthError.service")
            return
        }
    }
}
