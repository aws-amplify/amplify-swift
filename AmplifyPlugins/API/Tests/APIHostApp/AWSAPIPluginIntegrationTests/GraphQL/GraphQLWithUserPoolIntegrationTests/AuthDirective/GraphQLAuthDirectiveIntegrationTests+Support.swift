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
@testable import APIHostApp

extension GraphQLAuthDirectiveIntegrationTests {
    func createNote(_ id: String = UUID().uuidString,
                    content: String) -> Result<MutationSyncResult, GraphQLResponseError<MutationSyncResult>> {
        let createdNoteInvoked = expectation(description: "note was created")
        var resultOptional: Result<MutationSyncResult, GraphQLResponseError<MutationSyncResult>>?
        let note = SocialNote(id: id, content: content, owner: nil)
        let request = GraphQLRequest<MutationSyncResult>.createMutation(of: note)
        _ = Amplify.API.mutate(request: request, listener: { event in
            resultOptional = self.onMutationEvent(event)
            createdNoteInvoked.fulfill()
        })

        wait(for: [createdNoteInvoked], timeout: TestCommonConstants.networkTimeout)
        guard let result = resultOptional else {
            fatalError("Failed to create note")
        }
        return result
    }

    func updateNote(_ note: SocialNote,
                    version: Int) -> Result<MutationSyncResult, GraphQLResponseError<MutationSyncResult>> {
        let updateNoteInvoked = expectation(description: "note was updated")
        var resultOptional: Result<MutationSyncResult, GraphQLResponseError<MutationSyncResult>>?
        let request = GraphQLRequest<MutationSyncResult>.updateMutation(of: note, version: version)
        _ = Amplify.API.mutate(request: request, listener: { event in
            resultOptional = self.onMutationEvent(event)
            updateNoteInvoked.fulfill()
        })

        wait(for: [updateNoteInvoked], timeout: TestCommonConstants.networkTimeout)
        guard let result = resultOptional else {
            fatalError("Failed to update note")
        }
        return result
    }

    func deleteNote(byId id: String,
                    version: Int) -> Result<MutationSyncResult, GraphQLResponseError<MutationSyncResult>> {
        let deleteNoteInvoked = expectation(description: "note was deleted")
        var resultOptional: Result<MutationSyncResult, GraphQLResponseError<MutationSyncResult>>?
        let request = GraphQLRequest<MutationSyncResult>.deleteMutation(of: SocialNote(id: id, content: ""),
                                                                         modelSchema: SocialNote.schema,
                                                                         version: version)
        _ = Amplify.API.mutate(request: request, listener: { event in
            resultOptional = self.onMutationEvent(event)
            deleteNoteInvoked.fulfill()
        })

        wait(for: [deleteNoteInvoked], timeout: TestCommonConstants.networkTimeout)
        guard let result = resultOptional else {
            fatalError("Failed to delete note")
        }
        return result
    }

    func onMutationEvent(_ event: GraphQLOperation<MutationSyncResult>.OperationResult) ->
        Result<MutationSyncResult, GraphQLResponseError<MutationSyncResult>> {
            switch event {
            case .success(let data):
                switch data {
                case .success(let note):
                    return .success(note)
                case .failure(let error):
                    return .failure(error)
                }
            case .failure(let error):
                XCTFail("Got failed, error: \(error)")
            }
            fatalError("Failed to return response data")
    }

    func queryNote(byId id: String) -> Result<MutationSyncResult?, GraphQLResponseError<MutationSyncResult?>> {
        let queryNoteInvoked = expectation(description: "note was queried")
        var resultOptional: Result<MutationSyncResult?, GraphQLResponseError<MutationSyncResult?>>?
        let request = GraphQLRequest<MutationSyncResult?>.query(modelName: SocialNote.modelName, byId: id)
        _ = Amplify.API.query(request: request) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let note):
                    resultOptional = .success(note)
                case .failure(let error):
                    resultOptional = .failure(error)
                }
                queryNoteInvoked.fulfill()
            case .failure(let error):
                XCTFail("Got failed, error: \(error)")
            }
        }

        wait(for: [queryNoteInvoked], timeout: TestCommonConstants.networkTimeout)
        guard let result = resultOptional else {
            fatalError("Failed to query note")
        }
        return result
    }

    func syncQuery() -> Result<SyncQueryResult, GraphQLResponseError<SyncQueryResult>> {
        let syncQueryInvoked = expectation(description: "note was sync queried")
        var resultOptional: Result<SyncQueryResult, GraphQLResponseError<SyncQueryResult>>?
        let request = GraphQLRequest<SyncQueryResult>.syncQuery(modelType: SocialNote.self, limit: 1)
        _ = Amplify.API.query(request: request) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let paginatedNotes):
                    resultOptional = .success(paginatedNotes)
                case .failure(let error):
                    resultOptional = .failure(error)
                }
                syncQueryInvoked.fulfill()
            case .failure(let error):
                XCTFail("Got failed, error: \(error)")
            }
        }
        wait(for: [syncQueryInvoked], timeout: TestCommonConstants.networkTimeout)
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
