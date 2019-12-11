//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPICategoryPlugin
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPluginTestCommon
import AWSPluginsCore

class GraphQLSyncBasedTests: XCTestCase {

    static let amplifyConfiguration = "GraphQLSyncBasedTests-amplifyconfiguration"

    override func setUp() {
        Amplify.reset()
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

    override func tearDown() {
        Amplify.reset()
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
        guard let post = createPost(id: uuid, title: title) else {
            XCTFail("Failed to create post with version 1")
            return
        }
        let updatedTitle = title + "Updated"
        let modifiedPost = Post(id: post.id, title: updatedTitle, content: post.content, createdAt: Date())

        let completeInvoked = expectation(description: "request completed")
        var responseFromOperation: GraphQLResponse<MutationSync<AnyModel>>?
        let document = GraphQLSyncMutation(of: modifiedPost, type: .update, version: 1)
        let request = GraphQLRequest(document: document.stringValue,
                                     variables: document.variables,
                                     responseType: MutationSync<AnyModel>.self,
                                     decodePath: document.decodePath)

        _ = Amplify.API.mutate(request: request) { event in
            defer {
                completeInvoked.fulfill()
            }
            switch event {
            case .completed(let graphQLResponse):
                responseFromOperation = graphQLResponse
            case .failed(let apiError):
                XCTFail("\(apiError)")
            default:
                XCTFail("Could not get data back")
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
                }
            }
            return
        }

        XCTAssertEqual(mutationSync.model["title"] as? String, updatedTitle)
        XCTAssertEqual(mutationSync.model["content"] as? String, post.content)
        XCTAssertEqual(mutationSync.syncMetadata.version, 2)
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
        let document = GraphQLSyncQuery(from: Post.self, predicate: predicate, limit: 1, lastSync: 123)
        let request = GraphQLRequest(document: document.stringValue,
                                     variables: document.variables,
                                     responseType: PaginatedList<AnyModel>.self,
                                     decodePath: document.decodePath)

        _ = Amplify.API.query(request: request) { event in
            defer {
                completeInvoked.fulfill()
            }
            switch event {
            case .completed(let graphQLResponse):
                responseFromOperation = graphQLResponse
            case .failed(let error):
                print(error)
            default:
                XCTFail("Could not get data back")
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

        let document = GraphQLSubscription(of: Post.self, type: .onCreate)
        let request = GraphQLRequest(document: document.stringValue,
                                     variables: document.variables,
                                     responseType: MutationSync<AnyModel>.self,
                                     decodePath: document.decodePath)
        let operation = Amplify.API.subscribe(request: request) { event in
            switch event {
            case .inProcess(let graphQLResponse):
                switch graphQLResponse {
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
            case .failed(let error):
                print("Unexpected .failed event: \(error)")
            case .completed:
                completedInvoked.fulfill()
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
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

    func createPost(id: String, title: String) -> AmplifyTestCommon.Post? {
        let post = Post(id: id, title: title, content: "content", createdAt: Date())
        return createPost(post: post)
    }

    func createPost(post: AmplifyTestCommon.Post) -> AmplifyTestCommon.Post? {
        var result: AmplifyTestCommon.Post?
        let completeInvoked = expectation(description: "request completed")

        _ = Amplify.API.mutate(of: post, type: .create, listener: { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let post):
                    result = post
                default:
                    XCTFail("Could not get data back")
                }
                completeInvoked.fulfill()
            case .failed(let error):
                print(error)
            default:
                XCTFail("Could not get data back")
            }
        })
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

}
