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

/*
 Model Schema
 
 type Post @model @auth(rules: [{ allow: public }]) {
    id: ID!
    title: String!
    status: PostStatus!
    content: String!
  }
  
  enum PostStatus {
    ACTIVE
    INACTIVE
  }
 
 */

final class APIStressTests: XCTestCase {

    static let amplifyConfiguration = "testconfiguration/AWSGraphQLAPIStressTests-amplifyconfiguration"
    let concurrencyLimit = 50
    
    final public class TestModelRegistration: AmplifyModelRegistration {
        public func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Post.self)
        }
        
        public let version: String = "1"
    }
    
    override func setUp() async throws {
        await Amplify.reset()
        Amplify.Logging.logLevel = .verbose
        let plugin = AWSAPIPlugin(modelRegistration: TestModelRegistration())
        
        do {
            try Amplify.add(plugin: plugin)
            
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: Self.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }
    
    override func tearDown() async throws {
        await Amplify.reset()
    }

    // MARK: - Stress tests
    
    /// - Given: APIPlugin configured with valid configuration and schema
    /// - When: I create 50 subsciptions on createPost mutation and then create a Post
    /// - Then: Subscriptions should receive connected, disconnected  and progress events correctly
    func testMultipleSubscriptions() async throws {
        let connectedInvoked = expectation(description: "Connection established")
        connectedInvoked.expectedFulfillmentCount = concurrencyLimit
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        disconnectedInvoked.expectedFulfillmentCount = concurrencyLimit
        let completedInvoked = expectation(description: "Completed invoked")
        completedInvoked.expectedFulfillmentCount = concurrencyLimit
        let progressInvoked = expectation(description: "progress invoked")
        progressInvoked.expectedFulfillmentCount = concurrencyLimit

        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"

        let sequenceActor = SequenceActor()
        DispatchQueue.concurrentPerform(iterations: concurrencyLimit) { index in
            Task {
                let subscription = Amplify.API.subscribe(request: .subscription(of: Post.self, type: .onCreate))
                Task {
                    for try await subscriptionEvent in subscription {
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
                        case .data(let result):
                            switch result {
                            case .success(let post):
                                if post.id == uuid {
                                    progressInvoked.fulfill()
                                }
                            case .failure(let error):
                                XCTFail("\(error)")
                            }
                        }
                    }
                    completedInvoked.fulfill()
                }
                
                await sequenceActor.append(sequence: subscription)
            }
        }
        
        await fulfillment(of: [connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        
        let sequenceCount = await sequenceActor.sequences.count
        XCTAssertEqual(sequenceCount, concurrencyLimit)
        
        guard try await createPost(id: uuid, title: title) != nil else {
            XCTFail("Failed to create post")
            return
        }

        await fulfillment(of: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        
        DispatchQueue.concurrentPerform(iterations: concurrencyLimit) { index in
            Task {
                await sequenceActor.sequences[index].cancel()
            }
        }

        await fulfillment(of: [disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
    }
    
    /// - Given: APIPlugin configured with valid configuration and schema
    /// - When: I create 50 posts simultaneously
    /// - Then: Operation should succeed
    func testMultipleCreateMutations() async throws {
        let postCreateExpectation = expectation(description: "Post was created successfully")
        postCreateExpectation.expectedFulfillmentCount = concurrencyLimit
        DispatchQueue.concurrentPerform(iterations: concurrencyLimit) { index in
            Task {
                let id = UUID().uuidString
                let title = "title" + String(index)
                let post = try await createPost(id: id, title: title)
                XCTAssertNotNil(post)
                XCTAssertEqual(id, post?.id)
                XCTAssertEqual(title, post?.title)
                postCreateExpectation.fulfill()
            }
        }
        
        await fulfillment(of: [postCreateExpectation], timeout: TestCommonConstants.networkTimeout)
    }
    
    /// - Given: APIPlugin configured with valid configuration and schema and 50 posts saved
    /// - When: I update 50 post simultaneously
    /// - Then: Operation should succeed
    func testMultipleUpdateMutations() async throws {
        let postCreateExpectation = expectation(description: "Post was created successfully")
        postCreateExpectation.expectedFulfillmentCount = concurrencyLimit
        let postUpdateExpectation = expectation(description: "Post was updated successfully")
        postUpdateExpectation.expectedFulfillmentCount = concurrencyLimit
        let postActor = PostActor()
        
        DispatchQueue.concurrentPerform(iterations: concurrencyLimit) { index in
            Task {
                let id = UUID().uuidString
                let title = "title" + String(index)
                let post = try await createPost(id: id, title: title)
                XCTAssertNotNil(post)
                XCTAssertEqual(id, post?.id)
                XCTAssertEqual(title, post?.title)
                await postActor.append(post: post!)
                postCreateExpectation.fulfill()
            }
        }

        await fulfillment(of: [postCreateExpectation], timeout: TestCommonConstants.networkTimeout)
        
        DispatchQueue.concurrentPerform(iterations: concurrencyLimit) { index in
            Task {
                var post = await postActor.posts[index]
                post.title = "newTitle" + String(index)
                let updatedPost = try await mutatePost(post)
                XCTAssertNotNil(updatedPost)
                XCTAssertEqual(post.id, updatedPost.id)
                XCTAssertEqual(post.title, updatedPost.title)
                postUpdateExpectation.fulfill()
            }
        }
        
        await fulfillment(of: [postUpdateExpectation], timeout: TestCommonConstants.networkTimeout)
    }
    
    /// - Given: APIPlugin configured with valid configuration, schema and 50 posts saved
    /// - When: I delete 50 post simultaneously
    /// - Then: Operation should succeed
    func testMultipleDeleteMutations() async throws {
        let postCreateExpectation = expectation(description: "Post was created successfully")
        postCreateExpectation.expectedFulfillmentCount = concurrencyLimit

        let postDeleteExpectation = expectation(description: "Post was deleted successfully")
        postDeleteExpectation.expectedFulfillmentCount = concurrencyLimit

        let postActor = PostActor()
        
        DispatchQueue.concurrentPerform(iterations: concurrencyLimit) { index in
            Task {
                let id = UUID().uuidString
                let title = "title" + String(index)
                let post = try await createPost(id: id, title: title)
                XCTAssertNotNil(post)
                XCTAssertEqual(id, post?.id)
                XCTAssertEqual(title, post?.title)
                await postActor.append(post: post!)
                postCreateExpectation.fulfill()
            }
        }

        await fulfillment(of: [postCreateExpectation], timeout: TestCommonConstants.networkTimeout)
        
        DispatchQueue.concurrentPerform(iterations: concurrencyLimit) { index in
            Task {
                let post = await postActor.posts[index]
                let deletedPost = try await deletePost(post: post)
                XCTAssertNotNil(deletedPost)
                XCTAssertEqual(post.id, deletedPost.id)
                XCTAssertEqual(post.title, deletedPost.title)
                postDeleteExpectation.fulfill()
            }
        }
        
        await fulfillment(of: [postDeleteExpectation], timeout: TestCommonConstants.networkTimeout)
    }
    
    /// - Given: APIPlugin configured with valid configuration, schema and 50 posts saved
    /// - When: I query for 50 posts simultaneously
    /// - Then: Operation should succeed
    func testMultipleQueryByID() async throws {
        let postCreateExpectation = expectation(description: "Post was created successfully")
        postCreateExpectation.expectedFulfillmentCount = concurrencyLimit

        let postQueryExpectation = expectation(description: "Post was deleted successfully")
        postQueryExpectation.expectedFulfillmentCount = concurrencyLimit

        let postActor = PostActor()
        
        DispatchQueue.concurrentPerform(iterations: concurrencyLimit) { index in
            Task {
                let id = UUID().uuidString
                let title = "title" + String(index)
                let post = try await createPost(id: id, title: title)
                XCTAssertNotNil(post)
                XCTAssertEqual(id, post?.id)
                XCTAssertEqual(title, post?.title)
                await postActor.append(post: post!)
                postCreateExpectation.fulfill()
            }
        }

        await fulfillment(of: [postCreateExpectation], timeout: TestCommonConstants.networkTimeout)
        
        DispatchQueue.concurrentPerform(iterations: concurrencyLimit) { index in
            Task {
                let post = await postActor.posts[index]
                let graphQLResponse = try await Amplify.API.query(request: .get(Post.self, byId: post.id))
                guard case .success(let data) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                guard let queriedPost = data else {
                    XCTFail("Missing post from query")
                    return
                }
                XCTAssertNotNil(queriedPost)
                XCTAssertEqual(post.id, queriedPost.id)
                XCTAssertEqual(post.title, queriedPost.title)
                postQueryExpectation.fulfill()
            }
        }
        
        await fulfillment(of: [postQueryExpectation], timeout: TestCommonConstants.networkTimeout)
    }
    
    actor PostActor {
        var posts: [Post] = []
        func append(post: Post) {
            posts.append(post)
        }
    }
    
    actor SequenceActor {
        var sequences: [AmplifyAsyncThrowingSequence<GraphQLSubscriptionEvent<Post>>] = []
        func append(sequence: AmplifyAsyncThrowingSequence<GraphQLSubscriptionEvent<Post>>) {
            sequences.append(sequence)
        }
    }
    
    // MARK: - Helpers

    func createPost(id: String, title: String) async throws -> Post? {
        let post = Post(id: id, title: title, status: .active, content: "content")
        return try await createPost(post: post)
    }

    func createPost(post: Post) async throws -> Post? {
        let data = try await Amplify.API.mutate(request: .create(post))
        switch data {
        case .success(let post):
            return post
        case .failure(let error):
            throw error
        }
    }

    func mutatePost(_ post: Post) async throws -> Post {
        let data = try await Amplify.API.mutate(request: .update(post))
        switch data {
        case .success(let post):
            return post
        case .failure(let error):
            throw error
        }
    }

    func deletePost(post: Post) async throws -> Post {
        let data = try await Amplify.API.mutate(request: .delete(post))
        switch data {
        case .success(let post):
            return post
        case .failure(let error):
            throw error
        }
    }
}
