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

extension GraphQLAuthDirectiveIntegrationTests {
    func createNote(_ id: String = UUID().uuidString,
                    content: String) -> Result<MutationSyncResult, GraphQLResponseError<MutationSyncResult>> {
        let createdNoteInvoked = expectation(description: "note was created")
        var result: Result<MutationSyncResult, GraphQLResponseError<MutationSyncResult>>?
        let note = SocialNote(id: id, content: content, owner: nil)
        let request = GraphQLRequest<MutationSyncResult>.createMutation(of: note)
        _ = Amplify.API.mutate(request: request, listener: { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let note):
                    result = .success(note)
                case .failure(let error):
                    result = .failure(error)
                }
                createdNoteInvoked.fulfill()
            case .failed(let error):
                XCTFail("Got failed, error: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        })

        wait(for: [createdNoteInvoked], timeout: TestCommonConstants.networkTimeout)
        return result!
    }

    func updateNote(_ note: SocialNote,
                    version: Int) -> Result<MutationSyncResult, GraphQLResponseError<MutationSyncResult>> {
        let updateNoteInvoked = expectation(description: "note was update")
        var result: Result<MutationSyncResult, GraphQLResponseError<MutationSyncResult>>?
        let request = GraphQLRequest<MutationSyncResult>.updateMutation(of: note, version: version)
        _ = Amplify.API.mutate(request: request, listener: { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let note):
                    result = .success(note)
                case .failure(let error):
                    result = .failure(error)
                }
                updateNoteInvoked.fulfill()
            case .failed(let error):
                XCTFail("Got failed, error: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        })

        wait(for: [updateNoteInvoked], timeout: TestCommonConstants.networkTimeout)
        return result!
    }

    func deleteNote(byId id: String,
                    version: Int) -> Result<MutationSyncResult, GraphQLResponseError<MutationSyncResult>> {
        let deleteNoteInvoked = expectation(description: "note was deleted")
        var result: Result<MutationSyncResult, GraphQLResponseError<MutationSyncResult>>?
        let request = GraphQLRequest<MutationSyncResult>.deleteMutation(modelName: SocialNote.modelName,
                                                                        id: id,
                                                                        version: version)
        _ = Amplify.API.mutate(request: request, listener: { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let note):
                    result = .success(note)
                case .failure(let error):
                    result = .failure(error)
                }
                deleteNoteInvoked.fulfill()
            case .failed(let error):
                XCTFail("Got failed, error: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        })

        wait(for: [deleteNoteInvoked], timeout: TestCommonConstants.networkTimeout)
        return result!
    }

    func queryNote(byId id: String) -> Result<MutationSyncResult?, GraphQLResponseError<MutationSyncResult?>> {
        let queryNoteInvoked = expectation(description: "note was queried successfully")
        var result: Result<MutationSyncResult?, GraphQLResponseError<MutationSyncResult?>>?
        let request = GraphQLRequest<MutationSyncResult?>.query(modelName: SocialNote.modelName, byId: id)
        _ = Amplify.API.query(request: request) { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let note):
                    result = .success(note)
                case .failure(let error):
                    result = .failure(error)
                }
                queryNoteInvoked.fulfill()
            case .failed(let error):
                XCTFail("Got failed, error: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }

        wait(for: [queryNoteInvoked], timeout: TestCommonConstants.networkTimeout)
        return result!
    }

    func syncQuery() -> Result<SyncQueryResult, GraphQLResponseError<SyncQueryResult>> {
        let syncQueryInvoked = expectation(description: "sync query successfully")
        var result: Result<SyncQueryResult, GraphQLResponseError<SyncQueryResult>>?
        let request = GraphQLRequest<SyncQueryResult>.syncQuery(modelType: SocialNote.self, limit: 1)
        _ = Amplify.API.query(request: request) { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let paginatedNotes):
                    result = .success(paginatedNotes)
                case .failure(let error):
                    result = .failure(error)
                }
                syncQueryInvoked.fulfill()
            case .failed(let error):
                XCTFail("Got failed, error: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        wait(for: [syncQueryInvoked], timeout: TestCommonConstants.networkTimeout)
        return result!
    }

    func getAppSyncError(_ graphQLResponseError: GraphQLResponseError<MutationSyncResult>) -> AppSyncErrorType? {
        guard case let .error(errors) = graphQLResponseError,
            let error = errors.first,
            let extensions = error.extensions,
            case let .string(errorTypeValue) = extensions["errorType"] else {
                XCTFail("Other should not be able to update owner's note")
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

        guard case .notAuthenticated = authError else {
            XCTFail("Error should be AuthError.notAuthenticated")
            return
        }
    }
}
