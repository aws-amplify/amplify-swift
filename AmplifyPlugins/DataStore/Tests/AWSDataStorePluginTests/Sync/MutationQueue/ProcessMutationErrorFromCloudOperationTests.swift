//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStorePlugin

// swiftlint:disable type_body_length
// swiftlint:disable type_name
// swiftlint:disable file_length
class ProcessMutationErrorFromCloudOperationTests: XCTestCase {
    // swiftlint:enable type_name
    let defaultAsyncWaitTimeout = 10.0
    var mockAPIPlugin: MockAPICategoryPlugin!
    var storageAdapter: StorageEngineAdapter!
    var localPost = Post(title: "localTitle", content: "localContent", createdAt: .now())
    let queue = OperationQueue()

    override func setUp() async throws {
        await tryOrFail {
            try await setUpWithAPI()
        }
        storageAdapter = MockSQLiteStorageEngineAdapter()

        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)
    }

    /// - Given: APIError
    /// - When:
    ///    - APIError contains AuthError indicating user is not authenticated
    /// - Then:
    ///    - `DataStoreErrorHandler` is called
    func testProcessMutationErrorFromCloudOperationSuccessForAuthError() throws {
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .update)
        let authError = AuthError.signedOut("User is not authenticated", "Authenticate user", nil)
        let apiError = APIError.operationError("not signed in", "Sign In User", authError)
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            self.assertSuccessfulNil(result)
            expectCompletion.fulfill()
        }
        let expectErrorHandlerCalled = expectation(description: "Expect error handler called")
        let configuration = DataStoreConfiguration.custom(errorHandler: { error in
            guard let dataStoreError = error as? DataStoreError,
                case let .api(amplifyError, mutationEventOptional) = dataStoreError else {
                    XCTFail("Expected API error with mutationEvent")
                    return
            }
            guard let actualAPIError = amplifyError as? APIError,
                case let .operationError(_, _, underlyingError) = actualAPIError,
                let authError = underlyingError as? AuthError,
                case .signedOut = authError else {
                    XCTFail("Should be `signedOut` error")
                    return
            }
            guard let actualMutationEvent = mutationEventOptional else {
                XCTFail("Missing mutationEvent for api error")
                return
            }
            XCTAssertEqual(actualMutationEvent.id, mutationEvent.id)

            expectErrorHandlerCalled.fulfill()
        })

        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: configuration,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               apiError: apiError,
                                                               completion: completion)
        queue.addOperation(operation)
        wait(for: [expectErrorHandlerCalled, expectCompletion], timeout: defaultAsyncWaitTimeout)
    }

    /// - Given: APIError
    /// - When:
    ///    - APIError unrelated to AuthError
    /// - Then:
    ///    - `DataStoreErrorHandler` is called
    func testProcessMutationErrorFromCloudOperationSuccessForAPIError() throws {
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .update)
        let apiError = APIError.operationError("Operation failed", "", nil)
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            self.assertSuccessfulNil(result)
            expectCompletion.fulfill()
        }
        let expectErrorHandlerCalled = expectation(description: "Expect error handler called")
        let configuration = DataStoreConfiguration.custom(errorHandler: { error in
            guard let dataStoreError = error as? DataStoreError,
                  case let .api(amplifyError, mutationEventOptional) = dataStoreError else {
                XCTFail("Expected API error with mutationEvent")
                return
            }
            guard let actualAPIError = amplifyError as? APIError,
                  case .operationError = actualAPIError else {
                XCTFail("Missing APIError.operationError")
                return
            }
            guard let actualMutationEvent = mutationEventOptional else {
                XCTFail("Missing mutationEvent for api error")
                return
            }
            XCTAssertEqual(actualMutationEvent.id, mutationEvent.id)
            expectErrorHandlerCalled.fulfill()
        })

        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: configuration,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               apiError: apiError,
                                                               completion: completion)
        queue.addOperation(operation)
        wait(for: [expectErrorHandlerCalled, expectCompletion], timeout: defaultAsyncWaitTimeout)
    }

    /// - Given: GraphQLError with no errors
    /// - When:
    ///    - GraphQLError with no errors
    /// - Then:
    ///    - `DataStoreErrorHandler` is called
    func testProcessMutationErrorFromCloudOperationSuccessForGraphQLResponseWithNoErrors() throws {
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .delete)
        let graphQLResponseError = GraphQLResponseError<MutationSync<AnyModel>>.unknown("", "", nil)
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            self.assertSuccessfulNil(result)
            expectCompletion.fulfill()
        }
        let expectErrorHandlerCalled = expectation(description: "Expect error handler called")
        let configuration = DataStoreConfiguration.custom(errorHandler: { error in
            guard let dataStoreError = error as? DataStoreError,
                  case let .api(amplifyError, mutationEventOptional) = dataStoreError else {
                XCTFail("Expected API error with mutationEvent")
                return
            }
            guard let graphQLResponseError = amplifyError as?  GraphQLResponseError<MutationSync<AnyModel>>,
                  case .unknown = graphQLResponseError else {
                XCTFail("Missing GraphQLResponseError.unknown")
                return
            }
            guard let actualMutationEvent = mutationEventOptional else {
                XCTFail("Missing mutationEvent for api error")
                return
            }
            XCTAssertEqual(actualMutationEvent.id, mutationEvent.id)
            expectErrorHandlerCalled.fulfill()
        })

        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: configuration,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               graphQLResponseError: graphQLResponseError,
                                                               completion: completion)
        queue.addOperation(operation)
        wait(for: [expectErrorHandlerCalled, expectCompletion], timeout: defaultAsyncWaitTimeout)
    }

    /// - Given: GraphQLError with no error
    /// - When:
    ///    - GraphQLError with no error
    /// - Then:
    ///    - `DataStoreErrorHandler` is called
    func testProcessMutationErrorFromCloudOperationSuccessForGraphQLResponseWithNoErrorsArray() throws {
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .delete)
        let graphQLResponseError = GraphQLResponseError<MutationSync<AnyModel>>.error([])
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            self.assertSuccessfulNil(result)
            expectCompletion.fulfill()
        }
        let expectErrorHandlerCalled = expectation(description: "Expect error handler called")
        let configuration = DataStoreConfiguration.custom(errorHandler: { error in
            guard let dataStoreError = error as? DataStoreError,
                  case let .api(amplifyError, mutationEventOptional) = dataStoreError else {
                XCTFail("Expected API error with mutationEvent")
                return
            }
            guard let graphQLResponseError = amplifyError as?  GraphQLResponseError<MutationSync<AnyModel>>,
                  case .error(let errors) = graphQLResponseError else {
                XCTFail("Missing GraphQLResponseError.unknown")
                return
            }
            XCTAssertEqual(errors.count, 0)
            guard let actualMutationEvent = mutationEventOptional else {
                XCTFail("Missing mutationEvent for api error")
                return
            }
            XCTAssertEqual(actualMutationEvent.id, mutationEvent.id)
            expectErrorHandlerCalled.fulfill()
        })

        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: configuration,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               graphQLResponseError: graphQLResponseError,
                                                               completion: completion)
        queue.addOperation(operation)
        wait(for: [expectErrorHandlerCalled, expectCompletion], timeout: defaultAsyncWaitTimeout)
    }

    /// - Given: GraphQLError more than one error to handle
    /// - When:
    ///    - GraphQLError with multiple errors
    /// - Then:
    ///    - `DataStoreErrorHandler` is called
    func testProcessMutationErrorFromCloudOperationSuccessForGraphQLResponseWithMultipleErrors() throws {
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .delete)
        let error = GraphQLError(message: "error message")
        let graphQLResponseError = GraphQLResponseError<MutationSync<AnyModel>>.error([error, error])
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            self.assertSuccessfulNil(result)
            expectCompletion.fulfill()
        }
        let expectErrorHandlerCalled = expectation(description: "Expect error handler called")
        let configuration = DataStoreConfiguration.custom(errorHandler: { error in
            guard let dataStoreError = error as? DataStoreError,
                  case let .api(amplifyError, mutationEventOptional) = dataStoreError else {
                XCTFail("Expected API error with mutationEvent")
                return
            }
            guard let graphQLResponseError = amplifyError as?  GraphQLResponseError<MutationSync<AnyModel>>,
                  case .error(let errors) = graphQLResponseError else {
                XCTFail("Missing GraphQLResponseError.unknown")
                return
            }
            XCTAssertEqual(errors.count, 2)
            guard let actualMutationEvent = mutationEventOptional else {
                XCTFail("Missing mutationEvent for api error")
                return
            }
            XCTAssertEqual(actualMutationEvent.id, mutationEvent.id)
            expectErrorHandlerCalled.fulfill()
        })

        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: configuration,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               graphQLResponseError: graphQLResponseError,
                                                               completion: completion)
        queue.addOperation(operation)
        wait(for: [expectErrorHandlerCalled, expectCompletion], timeout: defaultAsyncWaitTimeout)
    }

    /// - Given: GraphQLError ConditionalCheck
    /// - When:
    ///    - GraphQLError with errors containing type ConditionalCheck
    /// - Then:
    ///    - `DataStoreErrorHandler` is called
    func testProcessMutationErrorFromCloudOperationSuccessForConditionalCheck() throws {
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .delete)
        let graphQLResponseError = GraphQLResponseError<MutationSync<AnyModel>>.error([graphQLError(.conditionalCheck)])

        let expectHubEvent = expectation(description: "Hub is notified")
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let expectErrorHandlerCalled = expectation(description: "Expect error handler called")
        let hubListener = Amplify.Hub.listen(to: .dataStore) { payload in
            if payload.eventName == "DataStore.conditionalSaveFailed" {
                expectHubEvent.fulfill()
            }
        }
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            self.assertSuccessfulNil(result)
            expectCompletion.fulfill()
        }
        let configuration = DataStoreConfiguration.custom(errorHandler: { error in
            guard let dataStoreError = error as? DataStoreError,
                  case let .api(amplifyError, mutationEventOptional) = dataStoreError else {
                XCTFail("Expected API error with mutationEvent")
                return
            }
            guard let graphQLResponseError = amplifyError as?  GraphQLResponseError<MutationSync<AnyModel>>,
                  case .error(let errors) = graphQLResponseError else {
                XCTFail("Missing GraphQLResponseError.unknown")
                return
            }
            XCTAssertEqual(errors.count, 1)
            guard let actualMutationEvent = mutationEventOptional else {
                XCTFail("Missing mutationEvent for api error")
                return
            }
            XCTAssertEqual(actualMutationEvent.id, mutationEvent.id)
            expectErrorHandlerCalled.fulfill()
        })

        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: configuration,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               graphQLResponseError: graphQLResponseError,
                                                               completion: completion)
        queue.addOperation(operation)
        wait(for: [expectHubEvent, expectErrorHandlerCalled, expectCompletion], timeout: defaultAsyncWaitTimeout)
        Amplify.Hub.removeListener(hubListener)
    }

    func testProcessMutationErrorFromCloudOperationSuccessForUnauthorized() throws {
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .delete)
        let graphQLResponseError = GraphQLResponseError<MutationSync<AnyModel>>.error([graphQLError(.unauthorized)])
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let expectErrorHandlerCalled = expectation(description: "Expect error handler called")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            self.assertSuccessfulNil(result)
            expectCompletion.fulfill()
        }
        let configuration = DataStoreConfiguration.custom(errorHandler: { error in
            guard let dataStoreError = error as? DataStoreError,
                  case let .api(amplifyError, mutationEventOptional) = dataStoreError else {
                XCTFail("Expected API error with mutationEvent")
                return
            }
            guard let graphQLResponseError = amplifyError as?  GraphQLResponseError<MutationSync<AnyModel>>,
                  case .error(let errors) = graphQLResponseError else {
                XCTFail("Missing GraphQLResponseError.unknown")
                return
            }
            XCTAssertEqual(errors.count, 1)
            guard let actualMutationEvent = mutationEventOptional else {
                XCTFail("Missing mutationEvent for api error")
                return
            }
            XCTAssertEqual(actualMutationEvent.id, mutationEvent.id)
            expectErrorHandlerCalled.fulfill()
        })

        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: configuration,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               graphQLResponseError: graphQLResponseError,
                                                               completion: completion)
        queue.addOperation(operation)
        wait(for: [expectErrorHandlerCalled, expectCompletion], timeout: defaultAsyncWaitTimeout)
    }

    func testProcessMutationErrorFromCloudOperationSuccessForOperationDisabled() throws {
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .delete)
        let graphQLResponseError = GraphQLResponseError<MutationSync<AnyModel>>.error([graphQLError(.operationDisabled)])
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let expectErrorHandlerCalled = expectation(description: "Expect error handler called")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            self.assertSuccessfulNil(result)
            expectCompletion.fulfill()
        }
        let configuration = DataStoreConfiguration.custom(errorHandler: { error in
            guard let dataStoreError = error as? DataStoreError,
                  case let .api(amplifyError, mutationEventOptional) = dataStoreError else {
                XCTFail("Expected API error with mutationEvent")
                return
            }
            guard let graphQLResponseError = amplifyError as?  GraphQLResponseError<MutationSync<AnyModel>>,
                  case .error(let errors) = graphQLResponseError else {
                XCTFail("Missing GraphQLResponseError")
                return
            }
            XCTAssertEqual(errors.count, 1)
            guard let actualMutationEvent = mutationEventOptional else {
                XCTFail("Missing mutationEvent for api error")
                return
            }
            XCTAssertEqual(actualMutationEvent.id, mutationEvent.id)
            expectErrorHandlerCalled.fulfill()
        })

        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: configuration,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               graphQLResponseError: graphQLResponseError,
                                                               completion: completion)
        queue.addOperation(operation)
        wait(for: [expectErrorHandlerCalled, expectCompletion], timeout: defaultAsyncWaitTimeout)
    }

    func testProcessMutationErrorFromCloudOperationSuccessForUnknownError() throws {
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .delete)
        let graphQLResponseError = GraphQLResponseError<MutationSync<AnyModel>>.error([graphQLError(.unknown("unknownErrorType"))])
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let expectErrorHandlerCalled = expectation(description: "Expect error handler called")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            self.assertSuccessfulNil(result)
            expectCompletion.fulfill()
        }
        let configuration = DataStoreConfiguration.custom(errorHandler: { error in
            guard let dataStoreError = error as? DataStoreError,
                  case let .api(amplifyError, mutationEventOptional) = dataStoreError else {
                XCTFail("Expected API error with mutationEvent")
                return
            }
            guard let graphQLResponseError = amplifyError as?  GraphQLResponseError<MutationSync<AnyModel>>,
                  case .error(let errors) = graphQLResponseError else {
                XCTFail("Missing GraphQLResponseError.unknown")
                return
            }
            XCTAssertEqual(errors.count, 1)
            guard let actualMutationEvent = mutationEventOptional else {
                XCTFail("Missing mutationEvent for api error")
                return
            }
            XCTAssertEqual(actualMutationEvent.id, mutationEvent.id)
            expectErrorHandlerCalled.fulfill()
        })

        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: configuration,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               graphQLResponseError: graphQLResponseError,
                                                               completion: completion)
        queue.addOperation(operation)
        wait(for: [expectErrorHandlerCalled, expectCompletion], timeout: defaultAsyncWaitTimeout)
    }

    /// - Given: Conflict Unhandled error
    /// - When:
    ///    - Error does not contain the remote model
    /// - Then:
    ///    - Unexpected scenario, there should never be an conflict unhandled error without error.data
    func testConflictUnhandledReturnsErrorForMissingRemoteModel() throws {
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .create)
        let graphQLError = GraphQLError(message: "conflict unhandled",
                                        extensions: ["errorType": .string(AppSyncErrorType.conflictUnhandled.rawValue)])
        let graphQLResponseError = GraphQLResponseError<MutationSync<AnyModel>>.error([graphQLError])
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            guard case let .failure(error) = result,
                let dataStoreError = error as? DataStoreError,
                case .unknown = dataStoreError else {
                XCTFail("Should have failed with DataStoreError.unknown")
                return
            }

            XCTAssertEqual(dataStoreError.errorDescription, "Missing remote model from the response from AppSync.")
            expectCompletion.fulfill()
        }
        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: .default,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               graphQLResponseError: graphQLResponseError,
                                                               completion: completion)
        queue.addOperation(operation)
        wait(for: [expectCompletion], timeout: defaultAsyncWaitTimeout)
    }

    /// - Given: Conflict Unhandled error
    /// - When:
    ///    - MutationType is `create`
    /// - Then:
    ///    - Unexpected scenario, there should never get a conflict for create mutations
    func testConflictUnhandledReturnsErrorForCreateMutation() throws {
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .create)
        let remotePost = Post(title: "remoteTitle", content: "remoteContent", createdAt: .now())
        guard let graphQLResponseError = try getGraphQLResponseError(withRemote: remotePost,
                                                                     deleted: false,
                                                                     version: 1) else {
            XCTFail("Couldn't get GraphQL response with remote post")
            return
        }
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            guard case let .failure(error) = result,
                let dataStoreError = error as? DataStoreError,
                case .unknown = dataStoreError else {
                XCTFail("Should have failed with DataStoreError.unknown")
                return
            }

            XCTAssertEqual(dataStoreError.errorDescription, "Should never get conflict unhandled for create mutation")
            expectCompletion.fulfill()
        }
        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: .default,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               graphQLResponseError: graphQLResponseError,
                                                               completion: completion)
        queue.addOperation(operation)
        wait(for: [expectCompletion], timeout: defaultAsyncWaitTimeout)
    }

    /// - Given: Conflict Unhandled error
    /// - When:
    ///    - MutationType is `delete`, remote model is deleted.
    /// - Then:
    ///    - No-op, operation finishes successfully
    func testConflictUnhandledForDeleteMutationAndDeletedRemoteModel() throws {
        let localPost = Post(title: "localTitle", content: "localContent", createdAt: .now())
        let remotePost = Post(id: localPost.id, title: "remoteTitle", content: "remoteContent", createdAt: .now())
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .delete)
        guard let graphQLResponseError = try getGraphQLResponseError(withRemote: remotePost,
                                                                     deleted: true,
                                                                     version: 1) else {
            XCTFail("Couldn't get GraphQL response with remote post")
            return
        }
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            self.assertSuccessfulNil(result)
            expectCompletion.fulfill()
        }
        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: .default,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               graphQLResponseError: graphQLResponseError,
                                                               completion: completion)
        queue.addOperation(operation)
        wait(for: [expectCompletion], timeout: defaultAsyncWaitTimeout)
    }

    /// - Given: Conflict Unhandled error
    /// - When:
    ///    - MutationType is `delete`, remote model is an update, conflict handler returns `.retryLocal`
    /// - Then:
    ///    - API is called to delete with local model
    func testConflictUnhandledForDeleteMutationAndUpdatedRemoteModelReturnsRetryLocal() throws {
        let localPost = Post(title: "localTitle", content: "localContent", createdAt: .now())
        let remotePost = Post(id: localPost.id, title: "remoteTitle", content: "remoteContent", createdAt: .now())
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .delete)
        guard let graphQLResponseError = try getGraphQLResponseError(withRemote: remotePost,
                                                                     deleted: false,
                                                                     version: 2) else {
            XCTFail("Couldn't get GraphQL response with remote post")
            return
        }
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            self.assertSuccessfulNil(result)
            expectCompletion.fulfill()
        }

        var eventListenerOptional: GraphQLOperation<MutationSync<AnyModel>>.ResultListener?
        let apiMutateCalled = expectation(description: "API was called")
        mockAPIPlugin.responders[.mutateRequestListener] =
            MutateRequestListenerResponder<MutationSync<AnyModel>> { request, eventListener in
                guard let variables = request.variables, let input = variables["input"] as? [String: Any] else {
                    XCTFail("The document variables property doesn't contain a valid input")
                    return nil
                }
                XCTAssert(input["id"] as? String == localPost.id)
                XCTAssert(request.document.contains("DeletePost"))
                eventListenerOptional = eventListener
                apiMutateCalled.fulfill()
                return nil
        }

        let expectConflicthandlerCalled = expectation(description: "Expect conflict handler called")
        let configuration = DataStoreConfiguration.custom(conflictHandler: { data, resolve  in
            guard let localPost = data.local as? Post,
                let remotePost = data.remote as? Post else {
                XCTFail("Couldn't get Posts from local and remote data")
                return
            }

            XCTAssertEqual(localPost.title, "localTitle")
            XCTAssertEqual(remotePost.title, "remoteTitle")
            expectConflicthandlerCalled.fulfill()
            resolve(.retryLocal)
        })

        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: configuration,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               graphQLResponseError: graphQLResponseError,
                                                               completion: completion)

        queue.addOperation(operation)

        wait(for: [expectConflicthandlerCalled], timeout: defaultAsyncWaitTimeout)
        wait(for: [apiMutateCalled], timeout: defaultAsyncWaitTimeout)
        guard let eventListener = eventListenerOptional else {
            XCTFail("Listener was not called through MockAPICategoryPlugin")
            return
        }
        let updatedMetadata = MutationSyncMetadata(modelId: remotePost.id,
                                                   modelName: remotePost.modelName,
                                                   deleted: true,
                                                   lastChangedAt: 0,
                                                   version: 3)
        let mockResponse = MutationSync(model: try localPost.eraseToAnyModel(), syncMetadata: updatedMetadata)
        eventListener(.success(.success(mockResponse)))

        wait(for: [expectCompletion], timeout: defaultAsyncWaitTimeout)
    }

    /// - Given: Conflict Unhandled error
    /// - When:
    ///    - MutationType is `delete`, remote model is an update, conflict handler returns `.retry(model)`
    /// - Then:
    ///    - API is called with the model from the conflict handler result
    func testConflictUnhandledForDeleteMutationAndUpdatedRemoteModelReturnsRetryModel() throws {
        let localPost = Post(title: "localTitle", content: "localContent", createdAt: .now())
        let remotePost = Post(id: localPost.id, title: "remoteTitle", content: "remoteContent", createdAt: .now())
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .delete)
        guard let graphQLResponseError = try getGraphQLResponseError(withRemote: remotePost,
                                                                     deleted: false,
                                                                     version: 2) else {
            XCTFail("Couldn't get GraphQL response with remote post")
            return
        }
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            self.assertSuccessfulNil(result)
            expectCompletion.fulfill()
        }

        let retryModel = Post(title: "retryModel", content: "retryContent", createdAt: .now())
        var eventListenerOptional: GraphQLOperation<MutationSync<AnyModel>>.ResultListener?
        let apiMutateCalled = expectation(description: "API was called")
        mockAPIPlugin.responders[.mutateRequestListener] =
            MutateRequestListenerResponder<MutationSync<AnyModel>> { request, eventListener in
                guard let variables = request.variables, let input = variables["input"] as? [String: Any] else {
                    XCTFail("The document variables property doesn't contain a valid input")
                    return nil
                }
                XCTAssert(input["title"] as? String == retryModel.title)
                XCTAssertTrue(request.document.contains("UpdatePost"))
                eventListenerOptional = eventListener
                apiMutateCalled.fulfill()
                return nil
        }

        let expectConflicthandlerCalled = expectation(description: "Expect conflict handler called")
        let configuration = DataStoreConfiguration.custom(conflictHandler: { data, resolve  in
            guard let localPost = data.local as? Post,
                let remotePost = data.remote as? Post else {
                XCTFail("Couldn't get Posts from local and remote data")
                return
            }

            XCTAssertEqual(localPost.title, "localTitle")
            XCTAssertEqual(remotePost.title, "remoteTitle")
            expectConflicthandlerCalled.fulfill()
            resolve(.retry(retryModel))
        })

        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: configuration,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               graphQLResponseError: graphQLResponseError,
                                                               completion: completion)

        queue.addOperation(operation)

        wait(for: [expectConflicthandlerCalled], timeout: defaultAsyncWaitTimeout)
        wait(for: [apiMutateCalled], timeout: defaultAsyncWaitTimeout)
        guard let eventListener = eventListenerOptional else {
            XCTFail("Listener was not called through MockAPICategoryPlugin")
            return
        }
        let updatedMetadata = MutationSyncMetadata(modelId: remotePost.id,
                                                   modelName: remotePost.modelName,
                                                   deleted: false,
                                                   lastChangedAt: 0,
                                                   version: 3)
        let mockResponse = MutationSync(model: try localPost.eraseToAnyModel(), syncMetadata: updatedMetadata)
        eventListener(.success(.success(mockResponse)))

        wait(for: [expectCompletion], timeout: defaultAsyncWaitTimeout)
    }

    /// - Given: Conflict Unhandled error
    /// - When:
    ///    - MutationType is `delete`, remote model is an update, conflict handler returns `.applyRemote`
    /// - Then:
    ///    - Local Store is reconciled(recreated) to remote model, result mutationEvent is `update`
    func testConflictUnhandledForDeleteMutationAndUpdatedRemoteModelReturnsApplyRemote() throws {
        let localPost = Post(title: "localTitle", content: "localContent", createdAt: .now())
        let remotePost = Post(id: localPost.id, title: "remoteTitle", content: "remoteContent", createdAt: .now())
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .delete)
        guard let graphQLResponseError = try getGraphQLResponseError(withRemote: remotePost,
                                                                     deleted: false,
                                                                     version: 2) else {
            XCTFail("Couldn't get GraphQL response with remote post")
            return
        }
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            guard case .success(let mutationEventOptional) = result,
                let mutationEvent = mutationEventOptional else {
                    XCTFail("Should have been successful")
                    return
            }
            XCTAssertEqual(mutationEvent.mutationType, "update")
            XCTAssertEqual(mutationEvent.modelId, remotePost.id)
            expectCompletion.fulfill()
        }

        let modelSavedEvent = expectation(description: "model saved event")
        modelSavedEvent.expectedFulfillmentCount = 2
        let storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.responders[.saveUntypedModel] = SaveUntypedModelResponder { model, completion in
            guard let savedPost = model as? Post else {
                XCTFail("Couldn't get Posts from local and remote data")
                return
            }
            XCTAssertEqual(savedPost.title, remotePost.title)
            modelSavedEvent.fulfill()
            completion(.success(model))
        }

        storageAdapter.responders[.saveModelCompletion] =
            SaveModelCompletionResponder<MutationSyncMetadata> { metadata, completion in
                XCTAssertEqual(metadata.deleted, false)
                XCTAssertEqual(metadata.version, 2)
                modelSavedEvent.fulfill()
                completion(.success(metadata))
        }

        let expectHubEvent = expectation(description: "Hub is notified")
        let hubListener = Amplify.Hub.listen(to: .dataStore) { payload in
            if payload.eventName == "DataStore.syncReceived" {
                expectHubEvent.fulfill()
            }
        }
        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: .default,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               graphQLResponseError: graphQLResponseError,
                                                               completion: completion)
        queue.addOperation(operation)

        wait(for: [modelSavedEvent], timeout: defaultAsyncWaitTimeout)
        wait(for: [expectHubEvent], timeout: defaultAsyncWaitTimeout)
        wait(for: [expectCompletion], timeout: defaultAsyncWaitTimeout)
        Amplify.Hub.removeListener(hubListener)
    }

    /// - Given: Conflict Unhandled error
    /// - When:
    ///    - MutationType is `update`, remote model is deleted
    /// - Then:
    ///    - Local model is deleted, result mutationEvent is `delete`
    func testConflictUnhandledForUpdateMutationAndDeletedRemoteModel() throws {
        let localPost = Post(title: "localTitle", content: "localContent", createdAt: .now())
        let remotePost = Post(id: localPost.id, title: "remoteTitle", content: "remoteContent", createdAt: .now())
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .update)
        guard let graphQLResponseError = try getGraphQLResponseError(withRemote: remotePost,
                                                                     deleted: true,
                                                                     version: 2) else {
            XCTFail("Couldn't get GraphQL response with remote post")
            return
        }
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            guard case .success(let mutationEventOptional) = result,
                let mutationEvent = mutationEventOptional else {
                XCTFail("Should have been successful")
                return
            }
            XCTAssertEqual(mutationEvent.mutationType, "delete")
            XCTAssertEqual(mutationEvent.modelId, localPost.id)
            expectCompletion.fulfill()
        }

        let modelDeletedEvent = expectation(description: "model deleted event")
        let metadataSavedEvent = expectation(description: "metadata saved event")
        let storageAdapter = MockSQLiteStorageEngineAdapter()
        storageAdapter.shouldReturnErrorOnDeleteMutation = false
        storageAdapter.responders[.deleteUntypedModel] = DeleteUntypedModelCompletionResponder { _ in
            modelDeletedEvent.fulfill()
            return .emptyResult
        }
        storageAdapter.responders[.saveModelCompletion] =
            SaveModelCompletionResponder<MutationSyncMetadata> { metadata, completion in
            XCTAssertEqual(metadata.deleted, true)
            XCTAssertEqual(metadata.version, 2)
            metadataSavedEvent.fulfill()
            completion(.success(metadata))
        }

        let expectHubEvent = expectation(description: "Hub is notified")
        let hubListener = Amplify.Hub.listen(to: .dataStore) { payload in
            if payload.eventName == "DataStore.syncReceived" {
                expectHubEvent.fulfill()
            }
        }
        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: .default,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               graphQLResponseError: graphQLResponseError,
                                                               completion: completion)

        queue.addOperation(operation)

        wait(for: [modelDeletedEvent], timeout: defaultAsyncWaitTimeout)
        wait(for: [metadataSavedEvent], timeout: defaultAsyncWaitTimeout)
        wait(for: [expectHubEvent], timeout: defaultAsyncWaitTimeout)
        wait(for: [expectCompletion], timeout: defaultAsyncWaitTimeout)
        Amplify.Hub.removeListener(hubListener)
    }

    /// - Given: Conflict Unhandled error
    /// - When:
    ///    - MutationType is `update`, remote model is an update, conflict handler returns `.applyRemote`
    /// - Then:
    ///    - Local model is updated with remote model data, result mutationEvent is `update`
    func testConflictUnhandledUpdateMutationAndUpdatedRemoteReturnsApplyRemote() throws {
        let localPost = Post(title: "localTitle", content: "localContent", createdAt: .now())
        let remotePost = Post(id: localPost.id, title: "remoteTitle", content: "remoteContent", createdAt: .now())
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .update)
        guard let graphQLResponseError = try getGraphQLResponseError(withRemote: remotePost,
                                                                     deleted: false,
                                                                     version: 2) else {
            XCTFail("Couldn't get GraphQL response with remote post")
            return
        }
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            guard case .success(let mutationEventOptional) = result,
                let mutationEvent = mutationEventOptional else {
                XCTFail("Should have been successful")
                return
            }
            XCTAssertEqual(mutationEvent.mutationType, "update")
            XCTAssertEqual(mutationEvent.modelId, remotePost.id)
            expectCompletion.fulfill()
        }

        let storageAdapter = MockSQLiteStorageEngineAdapter()
        let modelSavedEvent = expectation(description: "model saved event")
        let metadataSavedEvent = expectation(description: "metadata saved event")
        storageAdapter.responders[.saveUntypedModel] = SaveUntypedModelResponder { model, completion in
            guard let savedPost = model as? Post else {
                XCTFail("Couldn't get Posts from local and remote data")
                return
            }
            XCTAssertEqual(savedPost.title, remotePost.title)
            modelSavedEvent.fulfill()
            completion(.success(model))
        }
        storageAdapter.responders[.saveModelCompletion] =
            SaveModelCompletionResponder<MutationSyncMetadata> { metadata, completion in
            XCTAssertEqual(metadata.deleted, false)
            XCTAssertEqual(metadata.version, 2)
            metadataSavedEvent.fulfill()
            completion(.success(metadata))
        }

        let expectHubEvent = expectation(description: "Hub is notified")
        let hubListener = Amplify.Hub.listen(to: .dataStore) { payload in
            if payload.eventName == "DataStore.syncReceived" {
                expectHubEvent.fulfill()
            }
        }
        let expectConflicthandlerCalled = expectation(description: "Expect conflict handler called")
        let configuration = DataStoreConfiguration.custom(conflictHandler: { data, resolve  in
            guard let localPost = data.local as? Post,
                let remotePost = data.remote as? Post else {
                XCTFail("Couldn't get Posts from local and remote data")
                return
            }

            XCTAssertEqual(localPost.title, "localTitle")
            XCTAssertEqual(remotePost.title, "remoteTitle")
            expectConflicthandlerCalled.fulfill()
            resolve(.applyRemote)
        })
        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: configuration,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               graphQLResponseError: graphQLResponseError,
                                                               completion: completion)
        queue.addOperation(operation)

        wait(for: [expectConflicthandlerCalled], timeout: defaultAsyncWaitTimeout)
        wait(for: [modelSavedEvent], timeout: defaultAsyncWaitTimeout)
        wait(for: [metadataSavedEvent], timeout: defaultAsyncWaitTimeout)
        wait(for: [expectHubEvent], timeout: defaultAsyncWaitTimeout)
        wait(for: [expectCompletion], timeout: defaultAsyncWaitTimeout)
        Amplify.Hub.removeListener(hubListener)
    }

    /// - Given: Conflict Unhandled error
    /// - When:
    ///    - MutationType is `update`, remote model is an update, conflict handler returns `.retryLocal`
    /// - Then:
    ///    - API is called to update with the local model
    func testConflictUnhandledUpdateMutationAndUpdatedRemoteReturnsRetryLocal() throws {
        let localPost = Post(title: "localTitle", content: "localContent", createdAt: .now())
        let remotePost = Post(id: localPost.id, title: "remoteTitle", content: "remoteContent", createdAt: .now())
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .update)
        guard let graphQLResponseError = try getGraphQLResponseError(withRemote: remotePost,
                                                                     deleted: false,
                                                                     version: 2) else {
            XCTFail("Couldn't get GraphQL response with remote post")
            return
        }
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            guard case .success(let mutationEventOptional) = result else {
                XCTFail("Should have been successful")
                return
            }
            XCTAssertNil(mutationEventOptional)
            expectCompletion.fulfill()
        }

        var eventListenerOptional: GraphQLOperation<MutationSync<AnyModel>>.ResultListener?
        let apiMutateCalled = expectation(description: "API was called")
        mockAPIPlugin.responders[.mutateRequestListener] =
            MutateRequestListenerResponder<MutationSync<AnyModel>> { request, eventListener in
                guard let variables = request.variables, let input = variables["input"] as? [String: Any] else {
                    XCTFail("The document variables property doesn't contain a valid input")
                    return nil
                }
                XCTAssert(input["title"] as? String == localPost.title)
                XCTAssertTrue(request.document.contains("UpdatePost"))
                eventListenerOptional = eventListener
                apiMutateCalled.fulfill()
                return nil
        }

        let expectConflicthandlerCalled = expectation(description: "Expect conflict handler called")
        let configuration = DataStoreConfiguration.custom(conflictHandler: { data, resolve  in
            guard let localPost = data.local as? Post,
                let remotePost = data.remote as? Post else {
                XCTFail("Couldn't get Posts from local and remote data")
                return
            }

            XCTAssertEqual(localPost.title, "localTitle")
            XCTAssertEqual(remotePost.title, "remoteTitle")
            expectConflicthandlerCalled.fulfill()
            resolve(.retryLocal)
        })
        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: configuration,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               graphQLResponseError: graphQLResponseError,
                                                               completion: completion)

        queue.addOperation(operation)

        wait(for: [expectConflicthandlerCalled], timeout: defaultAsyncWaitTimeout)
        wait(for: [apiMutateCalled], timeout: defaultAsyncWaitTimeout)
        guard let eventListener = eventListenerOptional else {
            XCTFail("Listener was not called through MockAPICategoryPlugin")
            return
        }
        let updatedMetadata = MutationSyncMetadata(modelId: remotePost.id,
                                                   modelName: remotePost.modelName,
                                                   deleted: false,
                                                   lastChangedAt: 0,
                                                   version: 3)
        let mockResponse = MutationSync(model: try localPost.eraseToAnyModel(), syncMetadata: updatedMetadata)
        eventListener(.success(.success(mockResponse)))
        wait(for: [expectCompletion], timeout: defaultAsyncWaitTimeout)
    }

    /// - Given: Conflict Unhandled error
    /// - When:
    ///    - MutationType is `update`, remote model is an update, conflict handler returns `.retry(Model)`
    /// - Then:
    ///    - API is called to update the model from the conflict handler result
    func testConflictUnhandledUpdateMutationAndUpdatedRemoteReturnsRetryModel() throws {
        let localPost = Post(title: "localTitle", content: "localContent", createdAt: .now())
        let remotePost = Post(id: localPost.id, title: "remoteTitle", content: "remoteContent", createdAt: .now())
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .update)
        guard let graphQLResponseError = try getGraphQLResponseError(withRemote: remotePost,
                                                                     deleted: false,
                                                                     version: 2) else {
            XCTFail("Couldn't get GraphQL response with remote post")
            return
        }
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            guard case .success(let mutationEventOptional) = result else {
                XCTFail("Should have been successful")
                return
            }
            XCTAssertNil(mutationEventOptional)
            expectCompletion.fulfill()
        }

        let retryModel = Post(title: "retryModel", content: "retryContent", createdAt: .now())
        var eventListenerOptional: GraphQLOperation<MutationSync<AnyModel>>.ResultListener?
        let apiMutateCalled = expectation(description: "API was called")
        mockAPIPlugin.responders[.mutateRequestListener] =
            MutateRequestListenerResponder<MutationSync<AnyModel>> { request, eventListener in
                guard let variables = request.variables, let input = variables["input"] as? [String: Any] else {
                    XCTFail("The document variables property doesn't contain a valid input")
                    return nil
                }
                XCTAssert(input["title"] as? String == retryModel.title)
                XCTAssertTrue(request.document.contains("UpdatePost"))
                eventListenerOptional = eventListener
                apiMutateCalled.fulfill()
                return nil
        }

        let expectConflicthandlerCalled = expectation(description: "Expect conflict handler called")
        let configuration = DataStoreConfiguration.custom(conflictHandler: { data, resolve  in
            guard let localPost = data.local as? Post,
                let remotePost = data.remote as? Post else {
                XCTFail("Couldn't get Posts from local and remote data")
                return
            }

            XCTAssertEqual(localPost.title, "localTitle")
            XCTAssertEqual(remotePost.title, "remoteTitle")
            expectConflicthandlerCalled.fulfill()
            resolve(.retry(retryModel))
        })
        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: configuration,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               graphQLResponseError: graphQLResponseError,
                                                               completion: completion)
        queue.addOperation(operation)

        wait(for: [expectConflicthandlerCalled], timeout: defaultAsyncWaitTimeout)
        wait(for: [apiMutateCalled], timeout: defaultAsyncWaitTimeout)
        guard let eventListener = eventListenerOptional else {
            XCTFail("Listener was not called through MockAPICategoryPlugin")
            return
        }
        let updatedMetadata = MutationSyncMetadata(modelId: remotePost.id,
                                                   modelName: remotePost.modelName,
                                                   deleted: false,
                                                   lastChangedAt: 0,
                                                   version: 3)
        let mockResponse = MutationSync(model: try localPost.eraseToAnyModel(), syncMetadata: updatedMetadata)
        eventListener(.success(.success(mockResponse)))
        wait(for: [expectCompletion], timeout: defaultAsyncWaitTimeout)
    }

    /// - Given: Conflict Unhandled error
    /// - When:
    ///    - MutationType is `update`, remote model is an update, conflict handler returns `.retryLocal`
    ///    - API is called to update with local model and response contains error
    /// - Then:
    ///    - `DataStoreErrorHandler` is called
    func testConflictUnhandledSyncToCloudReturnsError() throws {
        let localPost = Post(title: "localTitle", content: "localContent", createdAt: .now())
        let remotePost = Post(id: localPost.id, title: "remoteTitle", content: "remoteContent", createdAt: .now())
        let mutationEvent = try MutationEvent(model: localPost, modelSchema: localPost.schema, mutationType: .update)
        guard let graphQLResponseError = try getGraphQLResponseError(withRemote: remotePost,
                                                                     deleted: false,
                                                                     version: 2) else {
            XCTFail("Couldn't get GraphQL response with remote post")
            return
        }
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            guard case .success(let mutationEventOptional) = result else {
                XCTFail("Should have been successful")
                return
            }
            XCTAssertNil(mutationEventOptional)
            expectCompletion.fulfill()
        }

        var eventListenerOptional: GraphQLOperation<MutationSync<AnyModel>>.ResultListener?
        let apiMutateCalled = expectation(description: "API was called")
        mockAPIPlugin.responders[.mutateRequestListener] =
            MutateRequestListenerResponder<MutationSync<AnyModel>> { request, eventListener in
                guard let variables = request.variables, let input = variables["input"] as? [String: Any] else {
                    XCTFail("The document variables property doesn't contain a valid input")
                    return nil
                }
                XCTAssert(input["title"] as? String == localPost.title)
                XCTAssertTrue(request.document.contains("UpdatePost"))
                eventListenerOptional = eventListener
                apiMutateCalled.fulfill()
                return nil
        }

        let expectConflicthandlerCalled = expectation(description: "Expect conflict handler called")
        let expectErrorHandlerCalled = expectation(description: "Expect error handler called")
        let configuration = DataStoreConfiguration.custom(errorHandler: { _ in
            expectErrorHandlerCalled.fulfill()
        }, conflictHandler: { data, resolve in
            guard let localPost = data.local as? Post,
                let remotePost = data.remote as? Post else {
                XCTFail("Couldn't get Posts from local and remote data")
                return
            }

            XCTAssertEqual(localPost.title, "localTitle")
            XCTAssertEqual(remotePost.title, "remoteTitle")
            expectConflicthandlerCalled.fulfill()
            resolve(.retryLocal)
        })
        let operation = ProcessMutationErrorFromCloudOperation(dataStoreConfiguration: configuration,
                                                               mutationEvent: mutationEvent,
                                                               api: mockAPIPlugin,
                                                               storageAdapter: storageAdapter,
                                                               graphQLResponseError: graphQLResponseError,
                                                               completion: completion)
        queue.addOperation(operation)

        wait(for: [expectConflicthandlerCalled], timeout: defaultAsyncWaitTimeout)
        wait(for: [apiMutateCalled], timeout: defaultAsyncWaitTimeout)
        guard let eventListener = eventListenerOptional else {
            XCTFail("Listener was not called through MockAPICategoryPlugin")
            return
        }

        let error = GraphQLError(message: "some other error")
        eventListener(.success(.failure(.error([error]))))

        wait(for: [expectErrorHandlerCalled], timeout: defaultAsyncWaitTimeout)
        wait(for: [expectCompletion], timeout: defaultAsyncWaitTimeout)
    }

    /// Given: GraphQL "OperationDisabled" error
    /// - When:
    ///    - API is called and response contains an "OperationDisabled" error
    /// - Then:
    ///    - Completion handler is successfully called
    func testProcessOperationDisabledError() throws {
        let post = Post(title: "localTitle", content: "localContent", createdAt: .now())
        let mutationEvent = try MutationEvent(model: post, modelSchema: Post.schema, mutationType: .create)
        let expectCompletion = expectation(description: "Expect to complete error processing")
        let completion: (Result<MutationEvent?, Error>) -> Void = { result in
            if case .success(let mutationEventOptional) = result {
                XCTAssertNil(mutationEventOptional)
                expectCompletion.fulfill()
                return
            }
            XCTFail("Should have been successful")
        }

        let graphQLError = try getGraphQLResponseError(withRemote: post,
                                                       deleted: false,
                                                       version: 0,
                                                       errorType: .operationDisabled)

        let operation = ProcessMutationErrorFromCloudOperation(
            dataStoreConfiguration: DataStoreConfiguration.default,
            mutationEvent: mutationEvent,
            api: mockAPIPlugin,
            storageAdapter: storageAdapter,
            graphQLResponseError: graphQLError,
            completion: completion)

        queue.addOperation(operation)
        wait(for: [expectCompletion], timeout: defaultAsyncWaitTimeout)
    }
}

extension ProcessMutationErrorFromCloudOperationTests {
    private func setUpCore() async throws -> AmplifyConfiguration {
        await Amplify.reset()

        let dataStorePublisher = DataStorePublisher()
        let dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                                 storageEngineBehaviorFactory: MockStorageEngineBehavior.mockStorageEngineBehaviorFactory,
                                                 dataStorePublisher: dataStorePublisher,
                                                 validAPIPluginKey: "MockAPICategoryPlugin",
                                                 validAuthPluginKey: "MockAuthCategoryPlugin")
        try Amplify.add(plugin: dataStorePlugin)
        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStorePlugin": true
        ])

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        return amplifyConfig
    }

    private func setUpAPICategory(config: AmplifyConfiguration) throws -> AmplifyConfiguration {
        mockAPIPlugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: mockAPIPlugin)

        let apiConfig = APICategoryConfiguration(plugins: [
            "MockAPICategoryPlugin": true
        ])
        let amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: config.dataStore)
        return amplifyConfig
    }

    private func setUpWithAPI() async throws {
        let configWithoutAPI = try await setUpCore()
        let configWithAPI = try setUpAPICategory(config: configWithoutAPI)
        try Amplify.configure(configWithAPI)
    }

    private func assertSuccessfulNil(_ result: Result<MutationEvent?, Error>) {
        guard case .success(let mutationEventOptional) = result else {
            XCTFail("Should have been successful")
            return
        }
        XCTAssertNil(mutationEventOptional)
    }

    private func getGraphQLResponseError(withRemote post: Post = Post(title: "remoteTitle",
                                                                      content: "remoteContent",
                                                                      createdAt: .now()),
                                         deleted: Bool = false,
                                         version: Int = 1,
                                         errorType: AppSyncErrorType? = .conflictUnhandled)
        throws -> GraphQLResponseError<MutationSync<AnyModel>>? {
        guard let data = try post.toJSON().data(using: .utf8) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        let remoteData = try decoder.decode(JSONValue.self, from: data)
        guard case var .object(remoteDataObject) = remoteData else {
            return nil
        }
        remoteDataObject["_deleted"] = .boolean(deleted)
        remoteDataObject["_lastChangedAt"] = .number(123)
        remoteDataObject["_version"] = .number(Double(version))
        remoteDataObject["__typename"] = .string(post.modelName)
        if let errorType = errorType {
            let graphQLError = GraphQLError(message: "error message",
                                            extensions: ["errorType": .string(errorType.rawValue),
                                                         "data": .object(remoteDataObject)])
            return GraphQLResponseError<MutationSync<AnyModel>>.error([graphQLError])
        } else {
            let graphQLError = GraphQLError(message: "error message")
            return GraphQLResponseError<MutationSync<AnyModel>>.error([graphQLError])
        }
    }

    private func graphQLError(_ errorType: AppSyncErrorType) -> GraphQLError {
        GraphQLError(message: "message",
                     locations: nil,
                     path: nil,
                     extensions: ["errorType": .string(errorType.rawValue)])
    }
}
