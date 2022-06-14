//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
@testable import Amplify
@testable import AmplifyTestCommon
import AWSPluginsCore

// swiftlint:disable type_body_length
class GraphQLSyncBasedTests: XCTestCase {

    static let amplifyConfiguration = "testconfiguration/GraphQLSyncBasedTests-amplifyconfiguration"

    override func setUp() async throws {
        await Amplify.reset()
        let plugin = AWSAPIPlugin(modelRegistration: PostCommentModelRegistration())

        do {
            try Amplify.add(plugin: plugin)

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLSyncBasedTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: Comment.self)
            ModelRegistry.register(modelType: Post.self)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() async throws {
        await Amplify.reset()
    }

    // Given: No post created
    // When: Call get query to retrieve non-existent post
    // Then: The query result should be nil
    func testQueryNonExistentPostReturnsNil() {
        let completeInvoked = expectation(description: "request completed")
        var responseFromOperation: GraphQLResponse<MutationSync<AnyModel>?>?

        let id = UUID().uuidString
        let modelName = "Post"

        let request = GraphQLRequest<MutationSyncResult?>.query(modelName: modelName, byId: id)
        _ = Amplify.API.query(request: request) { event in
            defer {
                completeInvoked.fulfill()
            }
            switch event {
            case .success(let graphQLResponse):
                responseFromOperation = graphQLResponse
            case .failure(let apiError):
                XCTFail("\(apiError)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)

        guard let response = responseFromOperation else {
            XCTAssertNotNil(responseFromOperation)
            return
        }
        guard case .success(let mutationSyncOptional) = response else {
            switch response {
            case .success:
                break

            case .failure(let error):
                switch error {
                case .error(let errors):
                    XCTFail("errors: \(errors)")
                case .partial(let model, let errors):
                    XCTFail("partial: \(String(describing: model)), \(errors)")
                case .transformationError(let rawResponse, let apiError):
                    XCTFail("transformationError: \(rawResponse), \(apiError)")
                case .unknown(let errorDescription, let recoverySuggestion, _):
                    XCTFail("UnknownError: \(errorDescription), \(recoverySuggestion)")
                }
            }
            return
        }

        XCTAssertNil(mutationSyncOptional)
    }

    // Given: A newly created post
    // When: Call get query to retrieve the newly created post
    // Then: The query result should be the post with the latest version
    func testCreatePostThenQueryPost() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let createdPost = createPost(id: uuid, title: title) else {
            XCTFail("Failed to create post with version 1")
            return
        }

        let completeInvoked = expectation(description: "request completed")
        var responseFromOperation: GraphQLResponse<MutationSync<AnyModel>?>?

        let request = GraphQLRequest<MutationSyncResult?>.query(modelName: createdPost.model.modelName,
                                                                byId: createdPost.model.id)

        _ = Amplify.API.query(request: request) { event in
            defer {
                completeInvoked.fulfill()
            }
            switch event {
            case .success(let graphQLResponse):
                responseFromOperation = graphQLResponse
            case .failure(let apiError):
                XCTFail("\(apiError)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)

        guard let response = responseFromOperation else {
            XCTAssertNotNil(responseFromOperation)
            return
        }
        guard case .success(let mutationSyncOptional) = response else {
            switch response {
            case .success:
                break

            case .failure(let error):
                switch error {
                case .error(let errors):
                    XCTFail("errors: \(errors)")
                case .partial(let model, let errors):
                    XCTFail("partial: \(String(describing: model)), \(errors)")
                case .transformationError(let rawResponse, let apiError):
                    XCTFail("transformationError: \(rawResponse), \(apiError)")
                case .unknown(let errorDescription, let recoverySuggestion, _):
                    XCTFail("UnknownError: \(errorDescription), \(recoverySuggestion)")
                }
            }
            return
        }
        guard let mutationSync = mutationSyncOptional else {
            XCTFail("Missing MutationSync object")
            return
        }

        XCTAssertEqual(mutationSync.model["title"] as? String, title)
        XCTAssertEqual(mutationSync.model["content"] as? String, createdPost.model["content"] as? String)
        XCTAssertEqual(mutationSync.syncMetadata.version, 1)
    }

    // Given: A newly created post will have version 1
    // When: Call update mutation with with an updated title
    //       passing in version 1, which is the correct unmodified version
    // Then: The mutation result should be the post with the updated title.
    //       MutationSync metadata contains version 2
    func testCreatePostThenUpdatePostShouldHaveNewVersion() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let createdPost = createPost(id: uuid, title: title) else {
            XCTFail("Failed to create post with version 1")
            return
        }

        let updatedTitle = title + "Updated"

        let modifiedPost = Post(id: createdPost.model["id"] as? String ?? "",
                                title: updatedTitle,
                                content: createdPost.model["content"] as? String ?? "",
                                createdAt: .now())

        let completeInvoked = expectation(description: "request completed")
        var responseFromOperation: GraphQLResponse<MutationSync<AnyModel>>?

        let request = GraphQLRequest<MutationSyncResult>.updateMutation(of: modifiedPost, version: 1)

        _ = Amplify.API.mutate(request: request) { event in
            defer {
                completeInvoked.fulfill()
            }
            switch event {
            case .success(let graphQLResponse):
                responseFromOperation = graphQLResponse
            case .failure(let apiError):
                XCTFail("\(apiError)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)

        guard let response = responseFromOperation else {
            XCTAssertNotNil(responseFromOperation)
            return
        }

        guard case .success(let mutationSync) = response else {
            switch response {
            case .success:
                break

            case .failure(let error):
                switch error {
                case .error(let errors):
                    XCTFail("errors: \(errors)")
                case .partial(let model, let errors):
                    XCTFail("partial: \(model), \(errors)")
                case .transformationError(let rawResponse, let apiError):
                    XCTFail("transformationError: \(rawResponse), \(apiError)")
                case .unknown(let errorDescription, let recoverySuggestion, _):
                    XCTFail("UnknownError: \(errorDescription), \(recoverySuggestion)")
                }
            }
            return
        }

        XCTAssertEqual(mutationSync.model["title"] as? String, updatedTitle)
        XCTAssertEqual(mutationSync.model["content"] as? String, createdPost.model["content"] as? String)
        XCTAssertEqual(mutationSync.syncMetadata.version, 2)
    }

    // Given: A newly created post
    // When: Call update mutation with with an updated title
    //       with a condition that does not match the newly created post
    // Then: The mutation result in a successful response, with graphQL repsonse data containing error
    //       The error should be "ConditionalCheckFailedException"
    func testUpdatePostWithInvalidConditionShouldFailWithConditionalCheckFailed() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        let post = Post.keys
        guard let createdPost = createPost(id: uuid, title: title) else {
            XCTFail("Failed to create post with version 1")
            return
        }

        let updatedTitle = title + "Updated"

        let modifiedPost = Post(id: createdPost.model["id"] as? String ?? "",
                                title: updatedTitle,
                                content: createdPost.model["content"] as? String ?? "",
                                createdAt: .now())

        let completeInvoked = expectation(description: "request completed")
        var responseFromOperation: GraphQLResponse<MutationSync<AnyModel>>?

        let queryPredicate = post.title == "Does not match"
        let request = GraphQLRequest<MutationSyncResult>.updateMutation(of: modifiedPost,
                                                                        where: queryPredicate.graphQLFilter,
                                                                        version: 1)

        _ = Amplify.API.mutate(request: request) { event in
            defer {
                completeInvoked.fulfill()
            }
            switch event {
            case .success(let graphQLResponse):
                responseFromOperation = graphQLResponse
            case .failure(let apiError):
                XCTFail("\(apiError)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)

        guard let response = responseFromOperation else {
            XCTAssertNotNil(responseFromOperation)
            return
        }

        let conditionalFailedError = expectation(description: "error should be conditional request failed")
        switch response {
        case .success(let mutationSync):
            XCTFail("success: \(mutationSync)")
        case .failure(let error):
            switch error {
            case .error(let errors):
                XCTAssertEqual(errors.count, 1)
                guard let error = errors.first,
                    let extensions = error.extensions,
                    case let .string(errorTypeValue) = extensions["errorType"] else {
                        XCTFail("Failed to get errorType from extensions of the GraphQL error")
                        return
                }
                let errorType = AppSyncErrorType(errorTypeValue)
                XCTAssertEqual(errorType, .conditionalCheck)
                conditionalFailedError.fulfill()
            case .partial(let model, let errors):
                XCTFail("partial: \(model), \(errors)")
            case .transformationError(let rawResponse, let apiError):
                XCTFail("transformationError: \(rawResponse), \(apiError)")
            case .unknown(let errorDescription, let recoverySuggestion, _):
                XCTFail("UnknownError: \(errorDescription), \(recoverySuggestion)")
            }
        }

        wait(for: [conditionalFailedError], timeout: TestCommonConstants.networkTimeout)
    }

    // Given: A newly created post
    // When: Call update mutation, with updated title and version 1, twice
    // Then: The first mutation is successful, and second returns conflict unhandled exception due to older version.
    func testCreatePostThenUpdateTwiceWithConflictUnhandledException() throws {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let createdPost = createPost(id: uuid, title: title) else {
            XCTFail("Failed to create post with version 1")
            return
        }
        let updatedTitle = title + "Updated"
        let modifiedPost = Post(id: createdPost.model["id"] as? String ?? "",
                                title: updatedTitle,
                                content: createdPost.model["content"] as? String ?? "",
                                createdAt: .now())
        let firstUpdateSuccess = expectation(description: "first update mutation should be successful")

        let request = GraphQLRequest<MutationSyncResult>.updateMutation(of: modifiedPost,
                                                                        version: 1)
        _ = Amplify.API.mutate(request: request) { event in
            switch event {
            case .success:
                firstUpdateSuccess.fulfill()
            case .failure(let apiError):
                XCTFail("\(apiError)")
            }
        }
        wait(for: [firstUpdateSuccess], timeout: TestCommonConstants.networkTimeout)

        var responseFromOperation: GraphQLResponse<MutationSync<AnyModel>>?
        let secondUpdateFailed = expectation(
            description: "second update mutatiion request should failed with ConflictUnhandled errorType")

        _ = Amplify.API.mutate(request: request) { event in
            defer {
                secondUpdateFailed.fulfill()
            }
            switch event {
            case .success(let graphQLResponse):
                responseFromOperation = graphQLResponse
            case .failure(let apiError):
                XCTFail("\(apiError)")
            }
        }
        wait(for: [secondUpdateFailed], timeout: TestCommonConstants.networkTimeout)

        guard let response = responseFromOperation else {
            XCTAssertNotNil(responseFromOperation)
            return
        }

        let conflictUnhandledError = expectation(description: "error should be conflict unhandled")
        switch response {
        case .success(let mutationSync):
            XCTFail("success: \(mutationSync)")
        case .failure(let error):
            switch error {
            case .error(let errors):
                XCTAssertEqual(errors.count, 1)
                guard let error = errors.first, let extensions = error.extensions else {
                    XCTFail("Failed to get extensions of the GraphQL error")
                    return
                }
                guard case let .string(errorTypeValue) = extensions["errorType"] else {
                    XCTFail("Missing errorType")
                    return
                }
                let errorType = AppSyncErrorType(errorTypeValue)
                XCTAssertEqual(errorType, .conflictUnhandled)

                guard case let .object(dataObject) = extensions["data"] else {
                    XCTFail("Missing data")
                    return
                }

                let serializedJSON = try JSONEncoder().encode(dataObject)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
                let mutationSync = try decoder.decode(MutationSync<Post>.self, from: serializedJSON)
                XCTAssertEqual(mutationSync.model.title, updatedTitle)
                XCTAssertEqual(mutationSync.model.content, createdPost.model["content"] as? String)
                XCTAssertEqual(mutationSync.syncMetadata.version, 2)
                conflictUnhandledError.fulfill()
            case .partial(let model, let errors):
                XCTFail("partial: \(model), \(errors)")
            case .transformationError(let rawResponse, let apiError):
                XCTFail("transformationError: \(rawResponse), \(apiError)")
            case .unknown(let errorDescription, let recoverySuggestion, _):
                XCTFail("UnknownError: \(errorDescription), \(recoverySuggestion)")
            }
        }

        wait(for: [conflictUnhandledError], timeout: TestCommonConstants.networkTimeout)
    }

    // Given: Two newly created posts
    // When: Call sync query with limit of 1, to ensure that we get a nextToken back
    // Then: The result should be a PaginatedList contain all fields populated (items, startedAt, nextToken)
    func testQuerySyncWithLastSyncTime() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard createPost(id: uuid, title: title) != nil else {
            XCTFail("Failed to create post")
            return
        }
        let uuid2 = UUID().uuidString
        guard createPost(id: uuid2, title: title) != nil else {
            XCTFail("Failed to create post")
            return
        }

        let completeInvoked = expectation(description: "request completed")
        var responseFromOperation: GraphQLResponse<PaginatedList<AnyModel>>?
        let post = Post.keys
        let predicate = post.title == title
        let request = GraphQLRequest<SyncQueryResult>.syncQuery(modelType: Post.self,
                                                                where: predicate,
                                                                limit: 1,
                                                                lastSync: 123)

        _ = Amplify.API.query(request: request) { event in
            defer {
                completeInvoked.fulfill()
            }
            switch event {
            case .success(let graphQLResponse):
                responseFromOperation = graphQLResponse
            case .failure(let error):
                print(error)
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)

        guard let response = responseFromOperation else {
            XCTAssertNotNil(responseFromOperation)
            return
        }

        guard case .success(let paginatedList) = response else {
            switch response {
            case .success:
                break

            case .failure(let error):
                switch error {
                case .error(let errors):
                    XCTFail("errors: \(errors)")
                case .partial(let model, let errors):
                    XCTFail("partial: \(model), \(errors)")
                case .transformationError(let rawResponse, let apiError):
                    XCTFail("transformationError: \(rawResponse), \(apiError)")
                case .unknown(let errorDescription, let recoverySuggestion, _):
                    XCTFail("UnknownError: \(errorDescription), \(recoverySuggestion)")
                }
            }
            return
        }

        XCTAssertNotNil(paginatedList)
        XCTAssertNotNil(paginatedList.startedAt)
        XCTAssertNotNil(paginatedList.nextToken)
        XCTAssertNotNil(paginatedList.items)
        XCTAssert(!paginatedList.items.isEmpty)
        XCTAssert(paginatedList.items[0].model["title"] as? String == title)
        XCTAssertNotNil(paginatedList.items[0].model["content"] as? String)
        XCTAssert(paginatedList.items[0].syncMetadata.version != 0)
    }

    // Given: A subscription document created from a Syncable Model (Post), and responseType of MutationSync<AnyModel>
    // When: Create posts to trigger subscriptions
    // Then: The result should be the mutationSync objeect containing model and metadataSync
    func testSubscribeToSyncableModels() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"

        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "Progress invoked")
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: Post.self, subscriptionType: .onCreate)

        let operation = Amplify.API.subscribe(
            request: request,
            valueListener: { subscriptionEvent in
                switch subscriptionEvent {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        break
                    case .connected:
                        connectedInvoked.fulfill()
                    case .disconnected:
                        disconnectedInvoked.fulfill()
                    }

                case .data(let graphQLResponse):
                    switch graphQLResponse {
                    case .success(let mutationSync):
                        XCTAssertEqual(mutationSync.model["title"] as? String, title)
                        XCTAssertEqual(mutationSync.syncMetadata.version, 1)
                    case .failure(let error):
                        XCTFail(error.errorDescription)
                    }
                    progressInvoked.fulfill()
                }
        }, completionListener: { event in
            switch event {
            case .failure(let error):
                print("Unexpected .failed event: \(error)")
            case .success:
                completedInvoked.fulfill()
            }
        })

        XCTAssertNotNil(operation)
        wait(for: [connectedInvoked], timeout: TestCommonConstants.networkTimeout)

        guard createPost(id: uuid, title: title) != nil else {
            XCTFail("Failed to create post")
            return
        }

        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        operation.cancel()
        wait(for: [disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertTrue(operation.isFinished)
    }

    // MARK: Helpers

    func createPost(id: String, title: String) -> MutationSyncResult? {
        let post = Post(id: id, title: title,
                        content: "content",
                        createdAt: .now())
        return createPost(post: post)
    }

    func createPost(post: Post) -> MutationSyncResult? {
        var result: MutationSyncResult?
        let completeInvoked = expectation(description: "request completed")

        let request = GraphQLRequest<MutationSyncResult>.createMutation(of: post)
        _ = Amplify.API.mutate(request: request, listener: { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    result = post
                case .failure(let error):
                    XCTFail("Failed to create post \(error)")
                }
                completeInvoked.fulfill()
            case .failure(let error):
                print(error)
            }
        })
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}
