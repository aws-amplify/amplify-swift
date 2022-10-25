//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AmplifyPlugins
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

/*
 ```
 # 6 - Blog Post Comment
 type Blog6 @model {
   id: ID!
   name: String!
   posts: [Post6] @connection(keyName: "byBlog", fields: ["id"])
 }

 type Post6 @model @key(name: "byBlog", fields: ["blogID"]) {
   id: ID!
   title: String!
   blogID: ID!
   blog: Blog6 @connection(fields: ["blogID"])
   comments: [Comment6] @connection(keyName: "byPost", fields: ["id"])
 }

 type Comment6 @model @key(name: "byPost", fields: ["postID", "content"]) {
   id: ID!
   postID: ID!
   post: Post6 @connection(fields: ["postID"])
   content: String!
 }
 ```
 */

@available(iOS 13.0, *)
class DataStoreConnectionScenario6Tests: SyncEngineIntegrationTestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Blog6.self)
            registry.register(modelType: Post6.self)
            registry.register(modelType: Comment6.self)
        }

        let version: String = "1"
    }

    func testGetBlogThenFetchPostsThenFetchComments() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let blog = saveBlog(name: "name"),
              let post1 = savePost(title: "title", blog: blog),
              let post2 = savePost(title: "title", blog: blog),
              let comment1post1 = saveComment(post: post1, content: "content"),
              let comment2post1 = saveComment(post: post1, content: "content") else {
            XCTFail("Could not create blog, posts, and comments")
            return
        }
        let getBlogCompleted = expectation(description: "get blog complete")
        var resultPosts: List<Post6>?
        Amplify.DataStore.query(Blog6.self, byId: blog.id) { result in
            switch result {
            case .success(let queriedBlogOptional):
                guard let queriedBlog = queriedBlogOptional else {
                    XCTFail("Could not get blog")
                    return
                }
                XCTAssertEqual(queriedBlog.id, blog.id)
                resultPosts = queriedBlog.posts
                getBlogCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [getBlogCompleted], timeout: TestCommonConstants.networkTimeout)
        guard let posts = resultPosts else {
            XCTFail("Could not get posts")
            return
        }
        XCTAssertEqual(posts.count, 2)
        guard let fetchedPost = posts.first(where: { (post) -> Bool in
            post.id == post1.id
        }), let comments = fetchedPost.comments else {
            XCTFail("Could not set up - failed to get a post and its comments")
            return
        }
        XCTAssertEqual(comments.count, 2)
        XCTAssertTrue(comments.contains(where: { (comment) -> Bool in
            comment.id == comment1post1.id
        }))
        XCTAssertTrue(comments.contains(where: { (comment) -> Bool in
            comment.id == comment2post1.id
        }))
        if let post = comments[0].post {
            XCTAssertEqual(post.comments?.count, 2)
        }
    }

    func testGetCommentThenFetchPostThenFetchBlog() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let blog = saveBlog(name: "name"),
              let post = savePost(title: "title", blog: blog),
              let comment = saveComment(post: post, content: "content") else {
            XCTFail("Could not create blog, post, and comment")
            return
        }

        let getCommentCompleted = expectation(description: "get comment complete")
        var resultComment: Comment6?
        Amplify.DataStore.query(Comment6.self, byId: comment.id) { result in
            switch result {
            case .success(let queriedCommentOptional):
                guard let queriedComment = queriedCommentOptional else {
                    XCTFail("Could not get comment")
                    return
                }
                XCTAssertEqual(queriedComment.id, comment.id)
                resultComment = queriedComment
                getCommentCompleted.fulfill()
            case .failure(let response):
                XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [getCommentCompleted], timeout: TestCommonConstants.networkTimeout)

        guard let fetchedComment = resultComment else {
            XCTFail("Could not get comment")
            return
        }

        guard let fetchedPost = fetchedComment.post else {
            XCTFail("Post is nil, should be loaded")
            return
        }

        guard let fetchedBlog = fetchedPost.blog else {
            XCTFail("Blog is nil, should be loaded")
            return
        }

        XCTAssertEqual(fetchedPost.id, post.id)
        XCTAssertEqual(fetchedPost.title, post.title)

        XCTAssertEqual(fetchedBlog.id, blog.id)
        XCTAssertEqual(fetchedBlog.name, blog.name)
    }

    func testGetPostThenFetchBlogAndComment() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let blog = saveBlog(name: "name"),
              let post = savePost(title: "title", blog: blog),
              let comment = saveComment(post: post, content: "content") else {
            XCTFail("Could not create blog, post, and comment")
            return
        }

        let getPostCompleted = expectation(description: "get post complete")
        var resultPost: Post6?
        Amplify.DataStore.query(Post6.self, byId: post.id) { result in
            switch result {
            case .success(let queriedPostOptional):
                guard let queriedPost = queriedPostOptional else {
                    XCTFail("Could not get post")
                    return
                }
                XCTAssertEqual(queriedPost.id, post.id)
                resultPost = queriedPost
                getPostCompleted.fulfill()
            case .failure(let response):
                XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [getPostCompleted], timeout: TestCommonConstants.networkTimeout)

        guard let fetchedPost = resultPost else {
            XCTFail("Could not get post")
            return
        }

        guard let eagerlyLoadedBlog = fetchedPost.blog else {
            XCTFail("Blog is nil, should be loaded")
            return
        }

        XCTAssertEqual(eagerlyLoadedBlog.id, blog.id)
        XCTAssertEqual(eagerlyLoadedBlog.name, blog.name)
        if let postsInEagerlyLoadedBlog = eagerlyLoadedBlog.posts {
            XCTAssertEqual(postsInEagerlyLoadedBlog.count, 1)
            XCTAssertTrue(postsInEagerlyLoadedBlog.contains(where: {(postIn) -> Bool in
                postIn.id == post.id
            }))
            XCTAssertEqual(postsInEagerlyLoadedBlog[0].id, post.id)
        }

        guard let lazilyLoadedComments = fetchedPost.comments else {
            XCTFail("Could not get comments")
            return
        }

        guard case .notLoaded = lazilyLoadedComments.loadedState else {
            XCTFail("Should not be in loaded state")
            return
        }
        XCTAssertEqual(lazilyLoadedComments.count, 1)
        XCTAssertEqual(lazilyLoadedComments[0].id, comment.id)
        if let fetchedPost = lazilyLoadedComments[0].post {
            XCTAssertEqual(fetchedPost.id, post.id)
            XCTAssertEqual(fetchedPost.comments?.count, 1)
        }
    }

    /// Ensure that the delete with `.all` predicate works as expected.
    /// There may be additional blogs/post/comments from other tests that are being deleted as part of this test
    /// We ignore those and only assert that that 6 models created in this test were deleted successfully.
    func testDeleteAll() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForReady()
        var cancellables = Set<AnyCancellable>()
        let remoteEventReceived = expectation(description: "received mutation event with version 1")
        remoteEventReceived.expectedFulfillmentCount = 2
        let commentId1 = UUID().uuidString
        let commentId2 = UUID().uuidString
        Amplify.DataStore.publisher(for: Comment6.self).sink { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        } receiveValue: { mutationEvent in
            if mutationEvent.modelId == commentId1 && mutationEvent.version == 1 {
                remoteEventReceived.fulfill()
            }
            if mutationEvent.modelId == commentId2 && mutationEvent.version == 1 {
                remoteEventReceived.fulfill()
            }
        }.store(in: &cancellables)
        guard let blog = saveBlog(name: "name"),
              let post = savePost(title: "title", blog: blog),
              saveComment(id: commentId1, post: post, content: "content") != nil else {
            XCTFail("Could not create first set of blog, post, and comment")
            return
        }
        guard let blog2 = saveBlog(name: "name"),
              let post2 = savePost(title: "title", blog: blog2),
              saveComment(id: commentId2, post: post2, content: "content") != nil else {
            XCTFail("Could not create second set of blog, post, and comment")
            return
        }
        wait(for: [remoteEventReceived], timeout: 10)

        let outboxMutationProcessed = expectation(description: "received outboxMutationProcessed")
        var processedSoFar = 0
        Amplify.Hub.publisher(for: .dataStore)
            .sink { payload in
                let event = DataStoreHubEvent(payload: payload)
                switch event {
                case .outboxMutationProcessed(let mutationEvent):
                    if mutationEvent.modelName == Blog6.modelName,
                       let model = mutationEvent.element.model as? Blog6,
                       model.id == blog.id || model.id == blog2.id {
                        processedSoFar += 1
                    } else if mutationEvent.modelName == Post6.modelName,
                              let model = mutationEvent.element.model as? Post6,
                              model.id == post.id || model.id == post2.id {
                        processedSoFar += 1
                    } else if mutationEvent.modelName == Comment6.modelName,
                              let model = mutationEvent.element.model as? Comment6,
                              model.id == commentId1 || model.id == commentId2 {
                        processedSoFar += 1
                    }

                    Amplify.Logging.verbose("Processed so far \(processedSoFar)/6")
                    if processedSoFar == 6 {
                        outboxMutationProcessed.fulfill()
                    }
                default:
                    break
                }
            }.store(in: &cancellables)

        let deleteSuccess = expectation(description: "Delete all successful")
        Amplify.DataStore.delete(Blog6.self, where: QueryPredicateConstant.all) { result in
            switch result {
            case .success:
                deleteSuccess.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }

        wait(for: [deleteSuccess, outboxMutationProcessed], timeout: 10)
    }

    func saveBlog(id: String = UUID().uuidString, name: String) -> Blog6? {
        let blog = Blog6(id: id, name: name)
        var result: Blog6?
        let completeInvoked = expectation(description: "request completed")
        Amplify.DataStore.save(blog) { event in
            switch event {
            case .success(let data):
                result = data
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func savePost(id: String = UUID().uuidString, title: String, blog: Blog6) -> Post6? {
        let post = Post6(id: id, title: title, blog: blog)
        var result: Post6?
        let completeInvoked = expectation(description: "request completed")
        Amplify.DataStore.save(post) { event in
            switch event {
            case .success(let data):
                result = data
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func saveComment(id: String = UUID().uuidString, post: Post6, content: String) -> Comment6? {
        let comment = Comment6(id: id, post: post, content: content)
        var result: Comment6?
        let completeInvoked = expectation(description: "request completed")
        Amplify.DataStore.save(comment) { event in
            switch event {
            case .success(let data):
                result = data
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}
