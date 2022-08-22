//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
@testable import Amplify
@testable import APIHostApp

// swiftlint:disable type_body_length
class GraphQLModelBasedTests: XCTestCase {

    static let amplifyConfiguration = "testconfiguration/GraphQLModelBasedTests-amplifyconfiguration"

    final public class PostCommentModelRegistration: AmplifyModelRegistration {
        public func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Post.self)
            ModelRegistry.register(modelType: Comment.self)
        }

        public let version: String = "1"
    }

    
    override func setUp() async throws {
        await Amplify.reset()
        Amplify.Logging.logLevel = .verbose
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

    override func tearDown() async throws {
        await Amplify.reset()
    }

    func testQuerySinglePostWithModel() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let post = createPost(id: uuid, title: title) else {
            XCTFail("Failed to set up test")
            return
        }

        let requestInvokedSuccessfully = expectation(description: "request completed")
        _ = Amplify.API.query(request: .get(Post.self, byId: uuid)) { event in
            switch event {
            case .success(let graphQLResponse):
                guard case let .success(data) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                guard let resultPost = data else {
                    XCTFail("Missing post from query")
                    return
                }

                XCTAssertEqual(resultPost.id, post.id)
                XCTAssertEqual(resultPost.title, title)
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("Unexpected .failed event: \(error)")
            }
        }

        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
    }

    /// Test custom GraphQLRequest with nested list deserializes to generated Post Model
    ///
    /// - Given: A post containing a single comment
    /// - When:
    ///    - Query for the post with nested selection set containing list of comments
    /// - Then:
    ///    - The resulting post object contains the list of comments
    ///
    func testCustomQueryPostWithComments() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let post = createPost(id: uuid, title: title) else {
            XCTFail("Failed to set up test")
            return
        }
        guard createComment(content: "content", post: post) != nil else {
            XCTFail("Failed to create comment with post")
            return
        }

        let requestInvokedSuccessfully = expectation(description: "request completed")
        let document = """
        query getPost($id: ID!) {
          getPost(id: $id){
            id
            title
            content
            createdAt
            updatedAt
            draft
            rating
            status
            comments {
              items {
                id
                content
                createdAt
                updatedAt
                post {
                  id
                  title
                  content
                  createdAt
                  updatedAt
                  draft
                  rating
                  status
                }
              }
              nextToken
            }
          }
        }
        """
        let graphQLRequest = GraphQLRequest(document: document,
                                            variables: ["id": uuid],
                                            responseType: Post?.self,
                                            decodePath: "getPost")
        _ = Amplify.API.query(request: graphQLRequest) { event in
            switch event {
            case .success(let graphQLResponse):
                guard case let .success(data) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                guard let resultPost = data else {
                    XCTFail("Missing post from query")
                    return
                }

                XCTAssertEqual(resultPost.id, post.id)
                XCTAssertEqual(resultPost.title, title)
                guard let comments = resultPost.comments else {
                    XCTFail("Missing comments from post")
                    return
                }
                XCTAssertEqual(comments.count, 1)
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("Unexpected .failed event: \(error)")
            }
        }

        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
    }

    func testListQueryWithModel() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard createPost(id: uuid, title: title) != nil else {
            XCTFail("Failed to ensure at least one Post to be retrieved on the listQuery")
            return
        }

        let requestInvokedSuccessfully = expectation(description: "request completed")

        _ = Amplify.API.query(request: .list(Post.self)) { event in
            switch event {
            case .success(let graphQLResponse):
                guard case let .success(posts) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                XCTAssertTrue(!posts.isEmpty)
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("Unexpected .failed event: \(error)")
            }
        }

        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
    }

    func testListQueryWithPredicate() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let uniqueTitle = testMethodName + uuid + "Title"
        let createdPost = Post(id: uuid,
                               title: uniqueTitle,
                               content: "content",
                               createdAt: .now(),
                               draft: true,
                               rating: 12.3)
        guard createPost(post: createdPost) != nil else {
            XCTFail("Failed to ensure at least one Post to be retrieved on the listQuery")
            return
        }

        let requestInvokedSuccessfully = expectation(description: "request completed")
        let post = Post.keys
        let predicate = post.id == uuid &&
            post.title == uniqueTitle &&
            post.content == "content" &&
            post.createdAt == createdPost.createdAt &&
            post.rating == 12.3 &&
            post.draft == true

        _ = Amplify.API.query(request: .list(Post.self, where: predicate)) { event in
            switch event {
            case .success(let graphQLResponse):
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
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("Unexpected .failed event: \(error)")
            }
        }

        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
    }

    func testCreatPostWithModel() {
        let requestInvokedSuccessfully = expectation(description: "request completed")

        let post = Post(title: "title", content: "content", createdAt: .now())
        _ = Amplify.API.mutate(request: .create(post)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    XCTAssertEqual(post.title, "title")
                    requestInvokedSuccessfully.fulfill()
                case .failure(let error):
                    XCTFail("Unexpected response with error \(error)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
    }

    func testCreateCommentWithModel() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let createdPost = createPost(id: uuid, title: title) else {
            XCTFail("Failed to create a Post.")
            return
        }

        let requestInvokedSuccessfully = expectation(description: "request completed")
        let comment = Comment(content: "commentContent",
                              createdAt: .now(),
                              post: createdPost)
        _ = Amplify.API.mutate(request: .create(comment)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let comment):
                    XCTAssertEqual(comment.content, "commentContent")
                    XCTAssertNotNil(comment.post)
                    XCTAssertEqual(comment.post?.id, uuid)
                    requestInvokedSuccessfully.fulfill()
                case .failure(let error):
                    XCTFail("Unexpected response with error \(error)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeletePostWithModel() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let post = createPost(id: uuid, title: title) else {
            XCTFail("Failed to ensure at least one Post to be retrieved on the listQuery")
            return
        }

        let requestInvokedSuccessfully = expectation(description: "request completed")

        _ = Amplify.API.mutate(request: .delete(post)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    XCTAssertEqual(post.title, title)
                case .failure(let error):
                    XCTFail("\(error)")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)

        let queryComplete = expectation(description: "query complete")

        _ = Amplify.API.query(request: .get(Post.self, byId: uuid)) { event in
            switch event {
            case .success(let graphQLResponse):
                guard case let .success(post) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                XCTAssertNil(post)
                queryComplete.fulfill()
            case .failure(let error):
                XCTFail("Unexpected .failed event: \(error)")
            }
        }

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
        let requestInvokedSuccessfully = expectation(description: "request completed")
        _ = Amplify.API.mutate(request: .update(updatedPost)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    XCTAssertEqual(post.title, updatedTitle)
                case .failure(let error):
                    XCTFail("\(error)")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
    }

    func testOnCreatePostSubscriptionWithModel() async throws {
        let connectedInvoked = AsyncExpectation(description: "Connection established")
        let progressInvoked = AsyncExpectation(description: "progress invoked", expectedFulfillmentCount: 2)
        let uuid = UUID().uuidString
        let uuid2 = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        let task = try await Amplify.API.subscribe(request: .subscription(of: Post.self, type: .onCreate))
        let subscription = await task.subscription
        Task {
            for await subscriptionEvent in subscription {
                switch subscriptionEvent {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        break
                    case .connected:
                        await connectedInvoked.fulfill()
                    case .disconnected:
                        break
                    }
                case .data(let result):
                    switch result {
                    case .success(let post):
                        if post.id == uuid || post.id == uuid2 {
                            await progressInvoked.fulfill()
                        }
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }
            }
        }
        
        XCTAssertNotNil(task)
        try await AsyncExpectation.waitForExpectations([connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        
        let post = Post(id: uuid, title: title, content: "content", createdAt: .now())
        _ = try await Amplify.API.mutate(request: .create(post))
        let post2 = Post(id: uuid, title: title, content: "content", createdAt: .now())
        _ = try await Amplify.API.mutate(request: .create(post2))
        try await AsyncExpectation.waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)
        await task.cancel()
    }

    func testOnUpdatePostSubscriptionWithModel() async throws {
        let connectingInvoked = AsyncExpectation(description: "Connection connecting")
        let connectedInvoked = AsyncExpectation(description: "Connection established")
        let progressInvoked = AsyncExpectation(description: "progress invoked")

        let task = try await Amplify.API.subscribe(request: .subscription(of: Post.self, type: .onUpdate))
        let subscription = await task.subscription
        Task {
            for await subscriptionEvent in subscription {
                switch subscriptionEvent {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        await connectingInvoked.fulfill()
                    case .connected:
                        await connectedInvoked.fulfill()
                    case .disconnected:
                        break
                    }
                case .data:
                    await progressInvoked.fulfill()
                }
            }
        }
                                 
        try await AsyncExpectation.waitForExpectations([connectingInvoked, connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        let post = Post(id: uuid, title: title, content: "content", createdAt: .now())
        _ = try await Amplify.API.mutate(request: .create(post))
        _ = try await Amplify.API.mutate(request: .update(post))

        try await AsyncExpectation.waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)

        await task.cancel()
    }

    func testOnDeletePostSubscriptionWithModel() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")

        let operation = Amplify.API.subscribe(
            request: .subscription(of: Post.self, type: .onDelete),
            valueListener: { event in
                switch event {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        break
                    case .connected:
                        connectedInvoked.fulfill()
                    case .disconnected:
                        disconnectedInvoked.fulfill()
                    }
                case .data:
                    progressInvoked.fulfill()
                }
        },
            completionListener: { event in
                switch event {
                case .failure(let error):
                    XCTFail("Unexpected .failed event: \(error)")
                case .success:
                    completedInvoked.fulfill()
                }
        })
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

        let operation = Amplify.API.subscribe(
            request: .subscription(of: Comment.self, type: .onCreate),
            valueListener: { event in
                switch event {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        break
                    case .connected:
                        connectedInvoked.fulfill()
                    case .disconnected:
                        disconnectedInvoked.fulfill()
                    }
                case .data:
                    progressInvoked.fulfill()
                }
        },
            completionListener: { event in
                switch event {
                case .failure(let error):
                    XCTFail("Unexpected .failed event: \(error)")
                case .success:
                    completedInvoked.fulfill()
                }
        })
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

    func createPost(id: String, title: String, expect: XCTestExpectation? = nil) -> Post? {
        let post = Post(id: id, title: title, content: "content", createdAt: .now())
        return createPost(post: post, expect: expect)
    }

    func createComment(content: String, post: Post) -> Comment? {
        let comment = Comment(content: content, createdAt: .now(), post: post)
        return createComment(comment: comment)
    }

    func createPost(post: Post, expect: XCTestExpectation? = nil) -> Post? {
        var result: Post? = post
        
        let requestInvokedSuccessfully = expect ?? expectation(description: "request completed")

        _ = Amplify.API.mutate(request: .create(post)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    result = post
                default:
                    XCTFail("Create Post was not successful: \(data)")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        if expect == nil {
            wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
        }
        
        return result
    }

    func createComment(comment: Comment) -> Comment? {
        var result: Comment?
        let requestInvokedSuccessfully = expectation(description: "request completed")

        _ = Amplify.API.mutate(request: .create(comment)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let comment):
                    result = comment
                default:
                    XCTFail("Could not get data back")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func mutatePost(_ post: Post, expect: XCTestExpectation? = nil) -> Post? {
        var result: Post?
        let requestInvokedSuccessfully = expect ?? expectation(description: "request completed")
        _ = Amplify.API.mutate(request: .update(post)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    result = post
                default:
                    XCTFail("Could not get data back")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        if expect == nil {
            wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
        }
        return result
    }

    func deletePost(post: Post) -> Post? {
        var result: Post?
        let requestInvokedSuccessfully = expectation(description: "request completed")

        _ = Amplify.API.mutate(request: .delete(post)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    result = post
                default:
                    XCTFail("Could not get data back")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}
