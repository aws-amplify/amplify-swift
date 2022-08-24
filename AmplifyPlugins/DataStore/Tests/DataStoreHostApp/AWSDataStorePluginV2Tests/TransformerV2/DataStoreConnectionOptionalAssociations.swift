//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSDataStorePlugin

/*

 input AMPLIFY { globalAuthRule: AuthRule = { allow: public } } # FOR TESTING ONLY!

 type Blog8 @model {
     id: ID!
     name: String!
     customs: [MyCustomModel8]
     notes: [String]
     posts: [Post8] @hasMany(indexName: "postByBlog", fields: ["id"])
 }

 type Post8 @model {
     id: ID!
     name: String!
     blogId: ID @index(name: "postByBlog")
     randomId: String @index(name: "byRandom")
     blog: Blog8 @belongsTo(fields: ["blogId"])
     comments: [Comment8] @hasMany(indexName: "commentByPost", fields: ["id"])
 }

 type Comment8 @model {
     id: ID!
     content: String
     postId: ID @index(name: "commentByPost")
     post: Post8 @belongsTo(fields: ["postId"])
 }

 type MyCustomModel8 {
     id: ID!
     name: String!
     desc: String
     children: [MyNestedModel8]
 }

 type MyNestedModel8 {
     id: ID!
     nestedName: String!
     notes: [String]
 }
 */

class DataStoreConnectionOptionalAssociations: SyncEngineIntegrationV2TestBase {

    var token: UnsubscribeToken?

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Blog8.self)
            registry.register(modelType: Post8.self)
            registry.register(modelType: Comment8.self)
        }

        let version: String = "1"
    }

    func testSaveCommentThenQuery() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()

        guard let comment = saveComment() else {
            XCTFail("Failed to save comment")
            return
        }
        _ = queryComment(id: comment.id)
    }

    func testSavePostThenQuery() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()

        guard let post = savePost() else {
            XCTFail("Failed to save post")
            return
        }
        _ = queryPost(id: post.id)
    }

    func testSaveBlogThenQuery() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()

        guard let blog = saveBlog() else {
            XCTFail("Failed to save blog ")
            return
        }
        _ = queryBlog(id: blog.id)
    }

    func testSaveCommentThenUpdateWithPost() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard var comment = saveComment(),
              let post = savePost() else {
            XCTFail("Failed to save comment and post")
            return
        }
        comment.post = post
        guard let comment = saveComment(comment),
              let queriedComment = queryComment(id: comment.id) else {
            XCTFail("Failed to update and query comment")
            return
        }
        XCTAssertNotNil(queriedComment.post)
        XCTAssertEqual(queriedComment.post?.id, post.id)
        guard let queriedPost = queryPost(id: post.id),
              let lazyComments = queriedPost.comments,
              let firstLazyComment = lazyComments.first else {
            XCTFail("Couldn't get post, and its comments")
            return
        }
        XCTAssertEqual(firstLazyComment.id, comment.id)
        XCTAssertEqual(queriedPost.comments?.count, 1)
    }

    func testSavePostThenUpdateWithBlog() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard var post = savePost(),
              let blog = saveBlog() else {
            XCTFail("Failed to save post and blog")
            return
        }
        post.blog = blog
        guard let post = savePost(post),
              let queriedPost = queryPost(id: post.id) else {
            XCTFail("Failed to update and query post ")
            return
        }
        XCTAssertNotNil(queriedPost.blog)
        XCTAssertEqual(queriedPost.blog?.id, blog.id)
        guard let queriedBlog = queryBlog(id: blog.id),
              let lazyPosts = queriedBlog.posts,
              let firstLazyPost = lazyPosts.first else {
            XCTFail("Couldn't get blog, and its posts")
            return
        }
        XCTAssertEqual(firstLazyPost.id, post.id)
        XCTAssertEqual(queriedBlog.posts?.count, 1)
    }

    func testUpdateCommentWithPostAndPostWithBlog() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard var comment = saveComment(),
              var post = savePost(),
              let blog = saveBlog() else {
            XCTFail("Failed to save comment and post and blog")
            return
        }
        comment.post = post
        post.blog = blog
        guard let post = savePost(post),
              let comment = saveComment(comment),
              let queriedComment = queryComment(id: comment.id) else {
            XCTFail("Failed to update post, comment, and query comment")
            return
        }
        XCTAssertNotNil(queriedComment.post)
        XCTAssertEqual(queriedComment.post?.id, post.id)
        XCTAssertNotNil(queriedComment.post?.blog)
        XCTAssertEqual(queriedComment.post?.blog?.id, blog.id)
    }

    func testRemovePostFromCommentAndBlogFromPost() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let blog = saveBlog(),
              let post = savePost(withBlog: blog),
              let comment = saveComment(withPost: post) else {
            XCTFail("Failed to save blog, post, comment")
            return
        }
        guard var queriedComment = queryComment(id: comment.id),
              var queriedPost = queryPost(id: post.id) else {
            XCTFail("Failed to query comment and post")
            return
        }
        XCTAssertNotNil(queriedComment.post)
        XCTAssertEqual(queriedComment.post?.id, post.id)
        XCTAssertNotNil(queriedComment.post?.blog)
        XCTAssertEqual(queriedComment.post?.blog?.id, blog.id)
        XCTAssertNotNil(queriedPost.blog)
        XCTAssertEqual(queriedPost.blog?.id, blog.id)

        queriedComment.post = nil
        queriedPost.blog = nil
        guard savePost(queriedPost) != nil,
              saveComment(queriedComment) != nil else {
            XCTFail("Failed to update comment and post")
            return
        }
        guard let queriedCommentWithoutPost = queryComment(id: comment.id),
              let queriedPostWithoutBlog = queryPost(id: post.id) else {
            XCTFail("Failed to query comment and post")
            return
        }

        XCTAssertNil(queriedCommentWithoutPost.post)
        XCTAssertNil(queriedPostWithoutBlog.blog)
    }

    func testQueryAllPost() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        let querySuccess = expectation(description: "query success")
        Amplify.DataStore.query(Post8.self) { result in
            switch result {
            case .success(let posts):
                print("posts \(posts)")
                XCTAssertTrue(!posts.isEmpty)
                querySuccess.fulfill()
            case .failure(let error): print("error: \(error)")
            }
        }
        wait(for: [querySuccess], timeout: TestCommonConstants.networkTimeout)
    }

    func saveComment(_ comment: Comment8? = nil, withPost post: Post8? = nil) -> Comment8? {
        let commentToSave: Comment8
        if let comment = comment {
            commentToSave = comment
        } else {
            commentToSave = Comment8(content: "content", post: post)
        }

        let waitForSync = expectation(description: "synced")
        let saveSuccess = expectation(description: "save comment")
        var resultComment: Comment8?
        token = Amplify.Hub.listen(to: .dataStore) { payload in
            let event = DataStoreHubEvent(payload: payload)
            switch event {
            case .syncReceived(let mutationEvent):
                if mutationEvent.modelId == commentToSave.id {
                    waitForSync.fulfill()
                    if let token = self.token {
                        Amplify.Hub.removeListener(token)
                    }
                }
            default:
                break
            }
        }
        Amplify.DataStore.save(commentToSave) { result in
            switch result {
            case .success(let comment):
                resultComment = comment
                saveSuccess.fulfill()
            case .failure(let error):
                XCTFail("error \(error)")
            }
        }

        wait(for: [saveSuccess, waitForSync], timeout: TestCommonConstants.networkTimeout)
        return resultComment
    }

    func savePost(_ post: Post8? = nil, withBlog blog: Blog8? = nil) -> Post8? {
        let postToSave: Post8
        if let post = post {
            postToSave = post
        } else {
            postToSave = Post8(name: "name", randomId: "randomId", blog: blog)
        }

        let waitForSync = expectation(description: "synced")
        let saveSuccess = expectation(description: "save post")
        var resultPost: Post8?
        token = Amplify.Hub.listen(to: .dataStore) { payload in
            let event = DataStoreHubEvent(payload: payload)
            switch event {
            case .syncReceived(let mutationEvent):
                if mutationEvent.modelId == postToSave.id {
                    waitForSync.fulfill()
                    if let token = self.token {
                        Amplify.Hub.removeListener(token)
                    }
                }
            default:
                break
            }
        }
        Amplify.DataStore.save(postToSave) { result in
            switch result {
            case .success(let post):
                resultPost = post
                saveSuccess.fulfill()
            case .failure(let error):
                XCTFail("error \(error)")
            }
        }

        wait(for: [saveSuccess, waitForSync], timeout: TestCommonConstants.networkTimeout)
        return resultPost
    }

    func saveBlog(_ blog: Blog8? = nil) -> Blog8? {
        let blogToSave: Blog8
        if let blog = blog {
            blogToSave = blog
        } else {
            let nestedModel = MyNestedModel8(id: UUID().uuidString,
                                             nestedName: "nestedName",
                                             notes: ["notes1", "notes2"])
            let customModel = MyCustomModel8(id: UUID().uuidString,
                                             name: "name",
                                             desc: "desc",
                                             children: [nestedModel])
            blogToSave = Blog8(name: "name", customs: [customModel], notes: ["notes1", "notes2"])
        }

        let waitForSync = expectation(description: "synced")
        let saveSuccess = expectation(description: "save blog")
        var resultBlog: Blog8?
        token = Amplify.Hub.listen(to: .dataStore) { payload in
            let event = DataStoreHubEvent(payload: payload)
            switch event {
            case .syncReceived(let mutationEvent):
                if mutationEvent.modelId == blogToSave.id {
                    waitForSync.fulfill()
                    if let token = self.token {
                        Amplify.Hub.removeListener(token)
                    }
                }

            default:
                break
            }
        }
        Amplify.DataStore.save(blogToSave) { result in
            switch result {
            case .success(let blog):
                resultBlog = blog
                saveSuccess.fulfill()
            case .failure(let error):
                XCTFail("error \(error)")
            }
        }

        wait(for: [saveSuccess, waitForSync], timeout: TestCommonConstants.networkTimeout)
        return resultBlog
    }

    func queryComment(id: String) -> Comment8? {
        var resultComment: Comment8?
        let querySuccess = expectation(description: "query success")
        Amplify.DataStore.query(Comment8.self, byId: id) { result in
            switch result {
            case .success(let commentOptional):
                guard let comment = commentOptional else {
                    XCTFail("Missing comment")
                    return
                }
                resultComment = comment
                querySuccess.fulfill()
            case .failure(let error):
                XCTFail("error \(error)")
            }
        }
        wait(for: [querySuccess], timeout: TestCommonConstants.networkTimeout)
        return resultComment
    }

    func queryPost(id: String) -> Post8? {
        var resultPost: Post8?
        let querySuccess = expectation(description: "query success")
        Amplify.DataStore.query(Post8.self, byId: id) { result in
            switch result {
            case .success(let postOptional):
                guard let post = postOptional else {
                    XCTFail("Missing post")
                    return
                }
                resultPost = post
                querySuccess.fulfill()
            case .failure(let error):
                XCTFail("error \(error)")
            }
        }
        wait(for: [querySuccess], timeout: TestCommonConstants.networkTimeout)
        return resultPost
    }

    func queryBlog(id: String) -> Blog8? {
        var resultBlog: Blog8?
        let querySuccess = expectation(description: "query success")
        Amplify.DataStore.query(Blog8.self, byId: id) { result in
            switch result {
            case .success(let blogOptional):
                guard let blog = blogOptional else {
                    XCTFail("Missing blog")
                    return
                }
                print(blog)
                resultBlog = blog
                querySuccess.fulfill()
            case .failure(let error): print("error \(error)")
            }
        }
        wait(for: [querySuccess], timeout: TestCommonConstants.networkTimeout)
        return resultBlog
    }
}
