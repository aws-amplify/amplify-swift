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
    
    func testQuerySinglePostWithModel() async throws {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        let post = Post(id: uuid, title: title, content: "content", createdAt: .now())
        _ = try await Amplify.API.mutate(request: .create(post))
        let graphQLResponse = try await Amplify.API.query(request: .get(Post.self, byId: uuid))
        guard case .success(let data) = graphQLResponse else {
            XCTFail("Missing successful response")
            return
        }
        guard let resultPost = data else {
            XCTFail("Missing post from query")
            return
        }
        
        XCTAssertEqual(resultPost.id, post.id)
        XCTAssertEqual(resultPost.title, title)
    }
    
    /// Test custom GraphQLRequest with nested list deserializes to generated Post Model
    ///
    /// - Given: A post containing a single comment
    /// - When:
    ///    - Query for the post with nested selection set containing list of comments
    /// - Then:
    ///    - The resulting post object contains the list of comments
    ///
    func testCustomQueryPostWithComments() async throws {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        let post = Post(id: uuid, title: title, content: "content", createdAt: .now())
        _ = try await Amplify.API.mutate(request: .create(post))
        let comment = Comment(content: "commentContent",
                              createdAt: .now(),
                              post: post)
        _ = try await Amplify.API.mutate(request: .create(comment))
        
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
        let graphQLResponse = try await Amplify.API.query(request: graphQLRequest)
        guard case .success(let data) = graphQLResponse else {
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
    }
    
    func testListQueryWithModel() async throws {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        let post = Post(id: uuid, title: title, content: "content", createdAt: .now())
        _ = try await Amplify.API.mutate(request: .create(post))
        
        let graphQLResponse = try await Amplify.API.query(request: .list(Post.self))
        guard case .success(let posts) = graphQLResponse else {
            XCTFail("Missing successful response")
            return
        }
        XCTAssertTrue(!posts.isEmpty)
    }
    
    func testListQueryWithPredicate() async throws {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let uniqueTitle = testMethodName + uuid + "Title"
        let createdPost = Post(id: uuid,
                               title: uniqueTitle,
                               content: "content",
                               createdAt: .now(),
                               draft: true,
                               rating: 12.3)
        _ = try await Amplify.API.mutate(request: .create(createdPost))
        let post = Post.keys
        let predicate = post.id == uuid &&
        post.title == uniqueTitle &&
        post.content == "content" &&
        post.createdAt == createdPost.createdAt &&
        post.rating == 12.3 &&
        post.draft == true
        
        let graphQLResponse = try await Amplify.API.query(request: .list(Post.self, where: predicate))
        guard case .success(let posts) = graphQLResponse else {
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
    }
    
    func testCreatPostWithModel() async throws {
        let post = Post(title: "title", content: "content", createdAt: .now())
        let createdPostResult = try await Amplify.API.mutate(request: .create(post))
        guard case .success(let resultedPost) = createdPostResult else {
            XCTFail("Error creating a Post")
            return
        }
        XCTAssertEqual(resultedPost.title, "title")
    }
    
    func testCreateCommentWithModel() async throws {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        let post = Post(id: uuid, title: title, content: "content", createdAt: .now())
        _ = try await Amplify.API.mutate(request: .create(post))
        let comment = Comment(content: "commentContent",
                              createdAt: .now(),
                              post: post)
        let createdCommentResult = try await Amplify.API.mutate(request: .create(comment))
        guard case .success(let resultComment) = createdCommentResult else {
            XCTFail("Error creating a Comment")
            return
        }
        XCTAssertEqual(resultComment.content, "commentContent")
        XCTAssertNotNil(resultComment.post)
    }
    
    func testDeletePostWithModel() async throws {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        let post = Post(id: uuid, title: title, content: "content", createdAt: .now())
        _ = try await Amplify.API.mutate(request: .create(post))
        let deletedPostResult = try await Amplify.API.mutate(request: .delete(post))
        guard case .success(let deletedPost) = deletedPostResult else {
            XCTFail("Error deleting the Post \(deletedPostResult)")
            return
        }
        XCTAssertEqual(deletedPost.title, title)
        let getPostAfterDeleteCompleted = try await Amplify.API.query(request: .get(Post.self, byId: post.id))
        switch getPostAfterDeleteCompleted {
        case .success(let queriedDeletedPostOptional):
            guard queriedDeletedPostOptional == nil else {
                XCTFail("Should be nil after deletion")
                return
            }
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
    }
    
    func testUpdatePostWithModel() async throws {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        let post = Post(id: uuid, title: title, content: "content", createdAt: .now())
        _ = try await Amplify.API.mutate(request: .create(post))
        let updatedTitle = title + "Updated"
        let updatedPost = Post(id: uuid, title: updatedTitle, content: post.content, createdAt: post.createdAt)
        let updatedPostOptional = try await Amplify.API.mutate(request: .update(updatedPost))
        guard case .success(let updatedPosts) = updatedPostOptional else {
            XCTFail("Error Updating the Post \(updatedPostOptional)")
            return
        }
        XCTAssertEqual(updatedPosts.title, updatedTitle)
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
        let post2 = Post(id: uuid2, title: title, content: "content", createdAt: .now())
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
    
    func testOnDeletePostSubscriptionWithModel() async throws {
        let connectingInvoked = AsyncExpectation(description: "Connection connecting")
        let connectedInvoked = AsyncExpectation(description: "Connection established")
        let progressInvoked = AsyncExpectation(description: "progress invoked")
        
        let task = try await Amplify.API.subscribe(request: .subscription(of: Post.self, type: .onDelete))
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
        _ = try await Amplify.API.mutate(request: .delete(post))
        
        try await AsyncExpectation.waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)
        
        await task.cancel()
    }
    
    func testOnCreateCommentSubscriptionWithModel() async throws {
        let connectedInvoked = AsyncExpectation(description: "Connection established")
        let progressInvoked = AsyncExpectation(description: "progress invoked", expectedFulfillmentCount: 2)
        let uuid = UUID().uuidString
        let uuid2 = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        let task = try await Amplify.API.subscribe(request: .subscription(of: Comment.self, type: .onCreate))
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
                    case .success(let comment):
                        if comment.id == uuid || comment.id == uuid2 {
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
        let comment = Comment(id: uuid, content: "content", createdAt: .now(), post: post)
        _ = try await Amplify.API.mutate(request: .create(comment))
        let comment2 = Comment(id: uuid2, content: "content", createdAt: .now(), post: post)
        _ = try await Amplify.API.mutate(request: .create(comment2))
        try await AsyncExpectation.waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)
        await task.cancel()
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
