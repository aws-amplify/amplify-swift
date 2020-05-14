//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPICategoryPlugin
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPluginTestCommon

// swiftlint:disable type_body_length
class GraphQLModelBasedTests: XCTestCase {

    static let amplifyConfiguration = "GraphQLModelBasedTests-amplifyconfiguration"

    override func setUp() {
        Amplify.reset()
        let plugin = AWSAPIPlugin(modelRegistration: PostCommentModelRegistration())

        do {
            try Amplify.add(plugin: plugin)

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLModelBasedTests.amplifyConfiguration)
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

    func testQuerySinglePostWithModel() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let post = createPost(id: uuid, title: title) else {
            XCTFail("Failed to set up test")
            return
        }

        let completeInvoked = expectation(description: "request completed")
        _ = Amplify.API.query(from: Post.self, byId: uuid, listener: { event in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(data) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                guard let resultPost = data else {
                    XCTFail("Missing post from querySingle")
                    return
                }

                XCTAssertEqual(resultPost.id, post.id)
                XCTAssertEqual(resultPost.title, title)
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        })

        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testListQueryWithModel() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard createPost(id: uuid, title: title) != nil else {
            XCTFail("Failed to ensure at least one Post to be retrieved on the listQuery")
            return
        }

        let completeInvoked = expectation(description: "request completed")

        _ = Amplify.API.query(from: Post.self, where: nil, listener: { event in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(posts) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                XCTAssertTrue(!posts.isEmpty)
                print(posts)
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        })

        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testListQueryWithPredicate() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let uniqueTitle = testMethodName + uuid + "Title"
        let createdPost = Post(id: uuid,
                               title: uniqueTitle,
                               content: "content",
                               createdAt: Date(),
                               draft: true,
                               rating: 12.3)
        guard createPost(post: createdPost) != nil else {
            XCTFail("Failed to ensure at least one Post to be retrieved on the listQuery")
            return
        }

        let completeInvoked = expectation(description: "request completed")
        let post = Post.keys
        let predicate = post.id == uuid &&
            post.title == uniqueTitle &&
            post.content == "content" &&
            post.createdAt == createdPost.createdAt &&
            post.rating == 12.3 &&
            post.draft == true

        _ = Amplify.API.query(from: Post.self, where: predicate, listener: { event in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(posts) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                XCTAssertEqual(posts.count, 1)
                guard let singlePost = posts.first else {
                    XCTFail("Should only have a single post with the unique title")
                    return
                }
                XCTAssertEqual(singlePost.id, uuid)
                XCTAssertEqual(singlePost.title, uniqueTitle)
                XCTAssertEqual(singlePost.content, "content")
                XCTAssertEqual(singlePost.createdAt.iso8601String, createdPost.createdAt.iso8601String)
                XCTAssertEqual(singlePost.rating, 12.3)
                XCTAssertEqual(singlePost.draft, true)
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        })

        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testCreatPostWithModel() {
        let completeInvoked = expectation(description: "request completed")

        let post = Post(title: "title", content: "content", createdAt: Date())
        _ = Amplify.API.mutate(of: post, type: .create, listener: { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let post):
                    XCTAssertEqual(post.title, "title")
                    completeInvoked.fulfill()
                case .failure(let error):
                    XCTFail("Unexpected response with error \(error)")
                }
            case .failed(let error):
                print(error)
            default:
                XCTFail("Could not get data back")
            }
        })
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testCreateCommentWithModel() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let createdPost = createPost(id: uuid, title: title) else {
            XCTFail("Failed to create a Post.")
            return
        }

        let completeInvoked = expectation(description: "request completed")
        let comment = Comment(content: "commentContent", createdAt: Date(), post: createdPost)
        _ = Amplify.API.mutate(of: comment, type: .create, listener: { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let comment):
                    XCTAssertEqual(comment.content, "commentContent")
                    XCTAssertNotNil(comment.post)
                    XCTAssertEqual(comment.post.id, uuid)
                    completeInvoked.fulfill()
                case .failure(let error):
                    XCTFail("Unexpected response with error \(error)")
                }
            case .failed(let error):
                print(error)
            default:
                XCTFail("Could not get data back")
            }
        })
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeletePostWithModel() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let post = createPost(id: uuid, title: title) else {
            XCTFail("Failed to ensure at least one Post to be retrieved on the listQuery")
            return
        }

        let completeInvoked = expectation(description: "request completed")

        _ = Amplify.API.mutate(of: post, type: .delete, listener: { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let post):
                    XCTAssertEqual(post.title, title)
                case .failure(let error):
                    print(error)
                }
                completeInvoked.fulfill()
            case .failed(let error):
                print(error)
            default:
                XCTFail("Could not get data back")
            }
        })
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)

        let queryComplete = expectation(description: "query complete")

        _ = Amplify.API.query(from: Post.self, byId: uuid, listener: { event in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(post) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                XCTAssertNil(post)
                queryComplete.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        })

        wait(for: [queryComplete], timeout: TestCommonConstants.networkTimeout)
    }

    func testUpdatePostWithModel() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let post = createPost(id: uuid, title: title) else {
            XCTFail("Failed to ensure at least one Post to be retrieved on the listQuery")
            return
        }
        let updatedTitle = title + "Updated"
        let updatedPost = Post(id: uuid, title: updatedTitle, content: post.content, createdAt: post.createdAt)
        let completeInvoked = expectation(description: "request completed")
        _ = Amplify.API.mutate(of: updatedPost, type: .update, listener: { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let post):
                    XCTAssertEqual(post.title, updatedTitle)
                case .failure(let error):
                    print(error)
                }
                completeInvoked.fulfill()
            case .failed(let error):
                print(error)
            default:
                XCTFail("Could not get data back")
            }
        })
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testOnCreatePostSubscriptionWithModel() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")
        progressInvoked.expectedFulfillmentCount = 2

        let operation = Amplify.API.subscribe(from: Post.self, type: .onCreate) { event in
            switch event {
            case .inProcess(let graphQLResponse):
                print(graphQLResponse)
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

        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        operation.cancel()
        wait(for: [disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertTrue(operation.isFinished)
    }

    func testOnUpdatePostSubscriptionWithModel() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")

        let operation = Amplify.API.subscribe(from: Post.self, type: .onUpdate) { event in
            switch event {
            case .inProcess(let graphQLResponse):
                print(graphQLResponse)
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
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"

        guard createPost(id: uuid, title: title) != nil else {
            XCTFail("Failed to create post")
            return
        }

        guard updatePost(id: uuid, title: title) != nil else {
            XCTFail("Failed to update post")
            return
        }

        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        operation.cancel()
        wait(for: [disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertTrue(operation.isFinished)
    }

    func testOnDeletePostSubscriptionWithModel() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")

        let operation = Amplify.API.subscribe(from: Post.self, type: .onDelete) { event in
            switch event {
            case .inProcess(let graphQLResponse):
                print(graphQLResponse)
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
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"

        guard let post = createPost(id: uuid, title: title) else {
            XCTFail("Failed to create post")
            return
        }

        guard deletePost(post: post) != nil else {
            XCTFail("Failed to update post")
            return
        }

        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        operation.cancel()
        wait(for: [disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertTrue(operation.isFinished)
    }

    func testOnCreateCommentSubscriptionWithModel() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")

        let operation = Amplify.API.subscribe(from: Comment.self, type: .onCreate) { event in
            switch event {
            case .inProcess(let graphQLResponse):
                print(graphQLResponse)
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
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"

        guard let createdPost = createPost(id: uuid, title: title) else {
            XCTFail("Failed to create post")
            return
        }

        guard createComment(content: "content", post: createdPost) != nil else {
            XCTFail("Failed to create comment with post")
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

    func createComment(content: String, post: AmplifyTestCommon.Post) -> AmplifyTestCommon.Comment? {
        let comment = Comment(content: content, createdAt: Date(), post: post)
        return createComment(comment: comment)
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
                    XCTFail("Create Post was not successful: \(data)")
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

    func createComment(comment: AmplifyTestCommon.Comment) -> AmplifyTestCommon.Comment? {
        var result: AmplifyTestCommon.Comment?
        let completeInvoked = expectation(description: "request completed")

        _ = Amplify.API.mutate(of: comment, type: .create, listener: { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let comment):
                    result = comment
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

    func updatePost(id: String, title: String) -> AmplifyTestCommon.Post? {
        var result: AmplifyTestCommon.Post?
        let completeInvoked = expectation(description: "request completed")

        let post = Post(id: id, title: title, content: "content", createdAt: Date())
        _ = Amplify.API.mutate(of: post, type: .update, listener: { event in
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

    func deletePost(post: AmplifyTestCommon.Post) -> AmplifyTestCommon.Post? {
        var result: AmplifyTestCommon.Post?
        let completeInvoked = expectation(description: "request completed")

        _ = Amplify.API.mutate(of: post, type: .delete, listener: { event in
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
