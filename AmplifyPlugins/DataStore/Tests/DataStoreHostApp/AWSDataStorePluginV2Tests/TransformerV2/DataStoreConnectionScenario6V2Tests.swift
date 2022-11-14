//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSDataStorePlugin
@testable import DataStoreHostApp

/*
 ```
 # 6 - Blog Post Comment
 type Blog6V2 @model @auth(rules: [{allow: public}]) {
   id: ID!
   name: String!
   posts: [Post6V2] @hasMany(indexName: "byBlog", fields: ["id"])
 }

 type Post6V2 @model @auth(rules: [{allow: public}]) {
   id: ID!
   title: String!
   blogID: ID! @index(name: "byBlog")
   blog: Blog6V2 @belongsTo(fields: ["blogID"])
   comments: [Comment6V2] @hasMany(indexName: "byPost", fields: ["id"])
 }

 type Comment6V2 @model @auth(rules: [{allow: public}]) {
   id: ID!
   postID: ID! @index(name: "byPost", sortKeyFields: ["content"])
   post: Post6V2 @belongsTo(fields: ["postID"])
   content: String!
 }
 ```
 */

// swiftlint:disable type_body_length
class DataStoreConnectionScenario6V2Tests: SyncEngineIntegrationV2TestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Blog6V2.self)
            registry.register(modelType: Post6V2.self)
            registry.register(modelType: Comment6V2.self)
        }

        let version: String = "1"
    }

    func testGetBlogThenFetchPostsThenFetchComments() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        guard let blog = await saveBlog(name: "name"),
              let post1 = await savePost(title: "title", blog: blog),
              let _ = await savePost(title: "title", blog: blog),
              let comment1post1 = await saveComment(post: post1, content: "content"),
              let comment2post1 = await saveComment(post: post1, content: "content") else {
            XCTFail("Could not create blog, posts, and comments")
            return
        }
        var resultPosts: List<Post6V2>?
        let queriedBlogOptional = try await Amplify.DataStore.query(Blog6V2.self, byId: blog.id)
        guard let queriedBlog = queriedBlogOptional else {
            XCTFail("Could not get blog")
            return
        }
        XCTAssertEqual(queriedBlog.id, blog.id)
        resultPosts = queriedBlog.posts
        
        guard let posts = resultPosts else {
            XCTFail("Could not get posts")
            return
        }
        
        try await posts.fetch()
        XCTAssertEqual(posts.count, 2)
        guard let fetchedPost = posts.first(where: { (post) -> Bool in
            post.id == post1.id
        }), let comments = fetchedPost.comments else {
            XCTFail("Could not set up - failed to get a post and its comments")
            return
        }
        
        try await comments.fetch()
        XCTAssertEqual(comments.count, 2)
        XCTAssertTrue(comments.contains(where: { (comment) -> Bool in
            comment.id == comment1post1.id
        }))
        XCTAssertTrue(comments.contains(where: { (comment) -> Bool in
            comment.id == comment2post1.id
        }))
        if let post = comments[0].post {
            try await post.comments?.fetch()
            XCTAssertEqual(post.comments?.count, 2)
        }
    }

    func testGetCommentThenFetchPostThenFetchBlog() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        guard let blog = await saveBlog(name: "name"),
              let post = await savePost(title: "title", blog: blog),
              let comment = await saveComment(post: post, content: "content") else {
            XCTFail("Could not create blog, post, and comment")
            return
        }

        let queriedCommentOptional = try await Amplify.DataStore.query(Comment6V2.self, byId: comment.id)
        guard let queriedComment = queriedCommentOptional else {
            XCTFail("Could not get comment")
            return
        }
        XCTAssertEqual(queriedComment.id, comment.id)

        guard let fetchedPost = queriedComment.post else {
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

    func testGetPostThenFetchBlogAndComment() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        guard let blog = await saveBlog(name: "name"),
              let post = await savePost(title: "title", blog: blog),
              let comment = await saveComment(post: post, content: "content") else {
            XCTFail("Could not create blog, post, and comment")
            return
        }
        
        let queriedPostOptional = try await Amplify.DataStore.query(Post6V2.self, byId: post.id)
        guard let queriedPost = queriedPostOptional else {
            XCTFail("Could not get post")
            return
        }
        XCTAssertEqual(queriedPost.id, post.id)

        guard let eagerlyLoadedBlog = queriedPost.blog else {
            XCTFail("Blog is nil, should be loaded")
            return
        }

        XCTAssertEqual(eagerlyLoadedBlog.id, blog.id)
        XCTAssertEqual(eagerlyLoadedBlog.name, blog.name)
        if let postsInEagerlyLoadedBlog = eagerlyLoadedBlog.posts {
            try await postsInEagerlyLoadedBlog.fetch()
            XCTAssertEqual(postsInEagerlyLoadedBlog.count, 1)
            XCTAssertTrue(postsInEagerlyLoadedBlog.contains(where: {(postIn) -> Bool in
                postIn.id == post.id
            }))
            XCTAssertEqual(postsInEagerlyLoadedBlog[0].id, post.id)
        }

        guard let lazilyLoadedComments = queriedPost.comments else {
            XCTFail("Could not get comments")
            return
        }

        guard case .notLoaded = lazilyLoadedComments.loadedState else {
            XCTFail("Should not be in loaded state")
            return
        }
        try await lazilyLoadedComments.fetch()
        XCTAssertEqual(lazilyLoadedComments.count, 1)
        XCTAssertEqual(lazilyLoadedComments[0].id, comment.id)
        if let fetchedPost = lazilyLoadedComments[0].post {
            XCTAssertEqual(fetchedPost.id, post.id)
            try await fetchedPost.comments?.fetch()
            XCTAssertEqual(fetchedPost.comments?.count, 1)
        }
    }

    func testSaveBlog() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        guard let blog = await saveBlog(name: "name") else {
            XCTFail("Could not create blog")
            return
        }
        let createReceived = expectation(description: "Create notification received")
        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }
                guard let blogEvent = try? mutationEvent.decodeModel() as? Blog6V2, blogEvent.id == blog.id else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(blogEvent.name, blog.name)
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                    return
                }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        
        let queriedBlogOptional = try await Amplify.DataStore.query(Blog6V2.self, byId: blog.id)
        guard let queriedBlog = queriedBlogOptional else {
            XCTFail("Could not get blog")
            return
        }
        XCTAssertEqual(queriedBlog.id, blog.id)
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    func testSaveBlogPost() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        guard let blog = await saveBlog(name: "name"),
              let post1 = await savePost(title: "title", blog: blog),
              let post2 = await savePost(title: "title", blog: blog) else {
            XCTFail("Could not create blog, posts")
            return
        }
        
        let createReceived = expectation(description: "Create notification received")
        createReceived.expectedFulfillmentCount = 3 // 3 models (1 blog and 2 posts)
        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }
                if let blogEvent = try? mutationEvent.decodeModel() as? Blog6V2, blogEvent.id == blog.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(blogEvent.name, blog.name)
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    }
                }
                if let postEvent = try? mutationEvent.decodeModel() as? Post6V2, postEvent.id == post1.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(postEvent.title, post1.title)
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    }
                }
                if let postEvent = try? mutationEvent.decodeModel() as? Post6V2, postEvent.id == post2.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(postEvent.title, post2.title)
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    }
                }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        
        var resultPosts: List<Post6V2>?
        let queriedBlogOptional = try await Amplify.DataStore.query(Blog6V2.self, byId: blog.id)
        guard let queriedBlog = queriedBlogOptional else {
            XCTFail("Could not get blog")
            return
        }
        XCTAssertEqual(queriedBlog.id, blog.id)
        resultPosts = queriedBlog.posts
        guard let posts = resultPosts else {
            XCTFail("Could not get posts")
            return
        }
        try await posts.fetch()
        XCTAssertEqual(posts.count, 2)
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    func testSaveBlogPostComment() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        
        guard let blog = await saveBlog(name: "name"),
              let post = await savePost(title: "title", blog: blog),
              let comment = await saveComment(post: post, content: "content") else {
            XCTFail("Could not create blog, posts, and comments")
            return
        }
        
        let createReceived = expectation(description: "Create notification received")
        createReceived.expectedFulfillmentCount = 3 // 3 models (1 blog and 1 post and 1 comment)
        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }
                if let blogEvent = try? mutationEvent.decodeModel() as? Blog6V2, blogEvent.id == blog.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(blogEvent.name, blog.name)
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    }
                }
                if let postEvent = try? mutationEvent.decodeModel() as? Post6V2, postEvent.id == post.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(postEvent.title, post.title)
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    }
                }
                if let commentEvent = try? mutationEvent.decodeModel() as? Comment6V2, commentEvent.id == comment.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(commentEvent.content, comment.content)
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                        return
                    }
                }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        
        var resultPosts: List<Post6V2>?
        let queriedBlogOptional = try await Amplify.DataStore.query(Blog6V2.self, byId: blog.id)
        guard let queriedBlog = queriedBlogOptional else {
            XCTFail("Could not get blog")
            return
        }
        XCTAssertEqual(queriedBlog.id, blog.id)
        resultPosts = queriedBlog.posts
        
        guard let posts = resultPosts else {
            XCTFail("Could not get posts")
            return
        }
        try await posts.fetch()
        XCTAssertEqual(posts.count, 1)
        guard let fetchedPost = posts.first(where: { (postFetched) -> Bool in
            postFetched.id == post.id
        }), let comments = fetchedPost.comments else {
            XCTFail("Could not set up - failed to get a post and its comments")
            return
        }
        try await comments.fetch()
        XCTAssertEqual(comments.count, 1)
        XCTAssertTrue(comments.contains(where: { (commentFetched) -> Bool in
            commentFetched.id == comment.id
        }))
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    func testCascadeDeleteBlogDeletesPostAndComments() async throws {
        await setUp(withModels: TestModelRegistration(), logLevel: .verbose)
        try await startAmplifyAndWaitForSync()
        guard let blog = await saveBlog(name: "name"),
              let post = await savePost(title: "title", blog: blog),
              let comment = await saveComment(post: post, content: "content") else {
            XCTFail("Could not create blog, posts, and comments")
            return
        }
        let createReceived = expectation(description: "Create notification received")
        createReceived.expectedFulfillmentCount = 3 // 3 models (1 blog and 1 post and 1 comment)
        var hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }
                if let blogEvent = try? mutationEvent.decodeModel() as? Blog6V2, blogEvent.id == blog.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(blogEvent.name, blog.name)
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                    }
                } else if let postEvent = try? mutationEvent.decodeModel() as? Post6V2, postEvent.id == post.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(postEvent.title, post.title)
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                    }
                } else if let commentEvent = try? mutationEvent.decodeModel() as? Comment6V2, commentEvent.id == comment.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(commentEvent.content, comment.content)
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                    }
                }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)

        let deleteReceived = expectation(description: "Delete notification received")
        deleteReceived.expectedFulfillmentCount = 3 // 3 models due to cascade delete behavior
        hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }
                if let blogEvent = try? mutationEvent.decodeModel() as? Blog6V2, blogEvent.id == blog.id {
                    if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                        XCTAssertEqual(mutationEvent.version, 2)
                        deleteReceived.fulfill()
                    }
                } else if let postEvent = try? mutationEvent.decodeModel() as? Post6V2, postEvent.id == post.id {
                    if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                        XCTAssertEqual(mutationEvent.version, 2)
                        deleteReceived.fulfill()
                    }
                } else if let commentEvent = try? mutationEvent.decodeModel() as? Comment6V2, commentEvent.id == comment.id {
                    if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                        XCTAssertEqual(mutationEvent.version, 2)
                        deleteReceived.fulfill()
                    }
                }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        
        _ = try await Amplify.DataStore.delete(blog)
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)

    }

    func saveBlog(id: String = UUID().uuidString, name: String) async -> Blog6V2? {
        let blog = Blog6V2(id: id, name: name)
        var result: Blog6V2?
        do {
            result = try await Amplify.DataStore.save(blog)
        } catch(let error) {
            XCTFail("Failed \(error)")
        }
        return result
    }

    func savePost(id: String = UUID().uuidString, title: String, blog: Blog6V2) async -> Post6V2? {
        let post = Post6V2(id: id, title: title, blog: blog)
        var result: Post6V2?
        do {
            result = try await Amplify.DataStore.save(post)
        } catch(let error) {
            XCTFail("Failed \(error)")
        }
        return result
    }

    func saveComment(id: String = UUID().uuidString, post: Post6V2, content: String) async -> Comment6V2? {
        let comment = Comment6V2(id: id, post: post, content: content)
        var result: Comment6V2?
        do {
            result = try await Amplify.DataStore.save(comment)
        } catch(let error) {
            XCTFail("Failed \(error)")
        }
        return result
    }
}
