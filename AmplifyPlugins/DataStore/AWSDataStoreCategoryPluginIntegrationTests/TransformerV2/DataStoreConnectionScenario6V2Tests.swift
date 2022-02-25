//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

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

    func testGetBlogThenFetchPostsThenFetchComments() throws {
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
        var resultPosts: List<Post6V2>?
        Amplify.DataStore.query(Blog6V2.self, byId: blog.id) { result in
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
        try startAmplifyAndWaitForSync()
        guard let blog = saveBlog(name: "name"),
              let post = savePost(title: "title", blog: blog),
              let comment = saveComment(post: post, content: "content") else {
            XCTFail("Could not create blog, post, and comment")
            return
        }

        let getCommentCompleted = expectation(description: "get comment complete")
        var resultComment: Comment6V2?
        Amplify.DataStore.query(Comment6V2.self, byId: comment.id) { result in
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
        try startAmplifyAndWaitForSync()
        guard let blog = saveBlog(name: "name"),
              let post = savePost(title: "title", blog: blog),
              let comment = saveComment(post: post, content: "content") else {
            XCTFail("Could not create blog, post, and comment")
            return
        }

        let getPostCompleted = expectation(description: "get post complete")
        var resultPost: Post6V2?
        Amplify.DataStore.query(Post6V2.self, byId: post.id) { result in
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

    func testSaveBlog() throws {
        try startAmplifyAndWaitForSync()
        guard let blog = saveBlog(name: "name") else {
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
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        let getBlogCompleted = expectation(description: "get blog complete")
        Amplify.DataStore.query(Blog6V2.self, byId: blog.id) { result in
            switch result {
            case .success(let queriedBlogOptional):
                guard let queriedBlog = queriedBlogOptional else {
                    XCTFail("Could not get blog")
                    return
                }
                XCTAssertEqual(queriedBlog.id, blog.id)
                getBlogCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }

        wait(for: [getBlogCompleted, createReceived], timeout: TestCommonConstants.networkTimeout)
    }

    func testSaveBlogPost() throws {
        try startAmplifyAndWaitForSync()
        guard let blog = saveBlog(name: "name"),
              let post1 = savePost(title: "title", blog: blog),
              let post2 = savePost(title: "title", blog: blog) else {
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
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        let getBlogCompleted = expectation(description: "get blog complete")
        var resultPosts: List<Post6V2>?
        Amplify.DataStore.query(Blog6V2.self, byId: blog.id) { result in
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
        wait(for: [createReceived], timeout: TestCommonConstants.networkTimeout)
    }

    func testSaveBlogPostComment() throws {
        try startAmplifyAndWaitForSync()
        guard let blog = saveBlog(name: "name"),
              let post = savePost(title: "title", blog: blog),
              let comment = saveComment(post: post, content: "content") else {
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
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        let getBlogCompleted = expectation(description: "get blog complete")
        var resultPosts: List<Post6V2>?
        Amplify.DataStore.query(Blog6V2.self, byId: blog.id) { result in
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
        XCTAssertEqual(posts.count, 1)
        guard let fetchedPost = posts.first(where: { (postFetched) -> Bool in
            postFetched.id == post.id
        }), let comments = fetchedPost.comments else {
            XCTFail("Could not set up - failed to get a post and its comments")
            return
        }
        XCTAssertEqual(comments.count, 1)
        XCTAssertTrue(comments.contains(where: { (commentFetched) -> Bool in
            commentFetched.id == comment.id
        }))
        wait(for: [createReceived], timeout: TestCommonConstants.networkTimeout)
    }

    func testCascadeDeleteBlogDeletesPostAndComments() throws {
        try startAmplifyAndWaitForSync()
        guard let blog = saveBlog(name: "name"),
              let post = savePost(title: "title", blog: blog),
              let comment = saveComment(post: post, content: "content") else {
            XCTFail("Could not create blog, posts, and comments")
            return
        }
        let createReceived = expectation(description: "Create notification received")
        createReceived.expectedFulfillmentCount = 3 // 3 models (1 blog and 1 post and 1 comment)
        let deleteReceived = expectation(description: "Delete notification received")
        deleteReceived.expectedFulfillmentCount = 3 // 3 models due to cascade delete behavior
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
                    } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                        XCTAssertEqual(mutationEvent.version, 2)
                        deleteReceived.fulfill()
                    }
                } else if let postEvent = try? mutationEvent.decodeModel() as? Post6V2, postEvent.id == post.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(postEvent.title, post.title)
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                    } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                        XCTAssertEqual(mutationEvent.version, 2)
                        deleteReceived.fulfill()
                    }
                } else if let commentEvent = try? mutationEvent.decodeModel() as? Comment6V2, commentEvent.id == comment.id {
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(commentEvent.content, comment.content)
                        XCTAssertEqual(mutationEvent.version, 1)
                        createReceived.fulfill()
                    } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                        XCTAssertEqual(mutationEvent.version, 2)
                        deleteReceived.fulfill()
                    }
                }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        wait(for: [createReceived], timeout: TestCommonConstants.networkTimeout)

        let deleteBlogCompleted = expectation(description: "delete blog complete")
        Amplify.DataStore.delete(Blog6V2.self, withId: blog.id) { result in
            switch result {
            case .success:
                deleteBlogCompleted.fulfill()
            case .failure(let response):
                XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [deleteBlogCompleted, deleteReceived], timeout: TestCommonConstants.networkTimeout)

    }

    func saveBlog(id: String = UUID().uuidString, name: String) -> Blog6V2? {
        let blog = Blog6V2(id: id, name: name)
        var result: Blog6V2?
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

    func savePost(id: String = UUID().uuidString, title: String, blog: Blog6V2) -> Post6V2? {
        let post = Post6V2(id: id, title: title, blog: blog)
        var result: Post6V2?
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

    func saveComment(id: String = UUID().uuidString, post: Post6V2, content: String) -> Comment6V2? {
        let comment = Comment6V2(id: id, post: post, content: content)
        var result: Comment6V2?
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
