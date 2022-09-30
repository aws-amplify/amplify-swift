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
        await setUp(withModels: TestModelRegistration(), logLevel: .verbose)
        try await startAmplifyAndWaitForSync()

        guard let comment = try await saveComment() else {
            XCTFail("Failed to save comment")
            return
        }
        _ = try await queryComment(id: comment.id)
    }

    func testSavePostThenQuery() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        guard let post = try await savePost() else {
            XCTFail("Failed to save post")
            return
        }
        _ = try await queryPost(id: post.id)
    }

    func testSaveBlogThenQuery() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        guard let blog = try await saveBlog() else {
            XCTFail("Failed to save blog ")
            return
        }
        _ = try await queryBlog(id: blog.id)
    }

    func testSaveCommentThenUpdateWithPost() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        guard var comment = try await saveComment(),
              let post = try await savePost() else {
            XCTFail("Failed to save comment and post")
            return
        }
        comment.post = post
        guard let comment = try await saveComment(comment),
              let queriedComment = try await queryComment(id: comment.id) else {
            XCTFail("Failed to update and query comment")
            return
        }
        XCTAssertNotNil(queriedComment.post)
        XCTAssertEqual(queriedComment.post?.id, post.id)
        guard let queriedPost = try await queryPost(id: post.id),
              let lazyComments = queriedPost.comments else {
            XCTFail("Couldn't get post, and its comments")
            return
        }
        try await lazyComments.fetch()
        guard let firstLazyComment = lazyComments.first else {
            XCTFail("Couldn't get first comment")
            return
        }
        XCTAssertEqual(firstLazyComment.id, comment.id)
        XCTAssertEqual(queriedPost.comments?.count, 1)
    }

    func testSavePostThenUpdateWithBlog() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        guard var post = try await savePost(),
              let blog = try await saveBlog() else {
            XCTFail("Failed to save post and blog")
            return
        }
        post.blog = blog
        guard let post = try await savePost(post),
              let queriedPost = try await queryPost(id: post.id) else {
            XCTFail("Failed to update and query post ")
            return
        }
        XCTAssertNotNil(queriedPost.blog)
        XCTAssertEqual(queriedPost.blog?.id, blog.id)
        guard let queriedBlog = try await queryBlog(id: blog.id),
              let lazyPosts = queriedBlog.posts else {
            XCTFail("Couldn't get blog, and its posts")
            return
        }
        try await lazyPosts.fetch()
        guard let firstLazyPost = lazyPosts.first else {
            XCTFail("Couldn't get first post")
            return
        }
        XCTAssertEqual(firstLazyPost.id, post.id)
        XCTAssertEqual(queriedBlog.posts?.count, 1)
    }

    func testUpdateCommentWithPostAndPostWithBlog() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        guard var comment = try await saveComment(),
              var post = try await savePost(),
              let blog = try await saveBlog() else {
            XCTFail("Failed to save comment and post and blog")
            return
        }
        comment.post = post
        post.blog = blog
        guard let post = try await savePost(post),
              let comment = try await saveComment(comment),
              let queriedComment = try await queryComment(id: comment.id) else {
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
        try await startAmplifyAndWaitForSync()
        guard let blog = try await saveBlog(),
              let post = try await savePost(withBlog: blog),
              let comment = try await saveComment(withPost: post) else {
            XCTFail("Failed to save blog, post, comment")
            return
        }
        guard var queriedComment = try await queryComment(id: comment.id),
              var queriedPost = try await queryPost(id: post.id) else {
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
        // A mock GraphQL request is created to assert that the request variables contains the "postId"
        // with the value `nil` which is sent to the API to persist the removal of the association.
        let request = GraphQLRequest<Comment8>.createMutation(of: queriedComment, version: 1)
        guard let variables = request.variables,
              let input = variables["input"] as? [String: Any?],
              let postValue = input["postId"],
              postValue == nil else {
            XCTFail("Failed to retrieve input object from GraphQL variables")
            return
        }
        
        guard try await saveComment(queriedComment) != nil else {
            XCTFail("Failed to update comment")
            return
        }
        guard let queriedCommentWithoutPost = try await  queryComment(id: comment.id) else {
            XCTFail("Failed to query comment without post")
            return
        }
        
        XCTAssertNil(queriedCommentWithoutPost.post)
        
        queriedPost.blog = nil
        guard try await  savePost(queriedPost) != nil else {
            XCTFail("Failed to update post")
            return
        }
        
        guard let queriedPostWithoutBlog = try await queryPost(id: post.id) else {
            XCTFail("Failed to query post")
            return
        }
        XCTAssertNil(queriedPostWithoutBlog.blog)
    }

    func testQueryAllPost() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let queriedPosts = try await Amplify.DataStore.query(Post8.self)
        XCTAssertTrue(!queriedPosts.isEmpty)
    }

    func saveComment(_ comment: Comment8? = nil, withPost post: Post8? = nil) async throws -> Comment8? {
        let commentToSave: Comment8
        if let comment = comment {
            commentToSave = comment
        } else {
            commentToSave = Comment8(content: "content", post: post)
        }

        let waitForSync = asyncExpectation(description: "synced")
        token = Amplify.Hub.listen(to: .dataStore) { payload in
            let event = DataStoreHubEvent(payload: payload)
            switch event {
            case .syncReceived(let mutationEvent):
                if mutationEvent.modelId == commentToSave.id {
                    Task { await waitForSync.fulfill() }
                    if let token = self.token {
                        Amplify.Hub.removeListener(token)
                    }
                }
            default:
                break
            }
        }
        let savedComment = try await Amplify.DataStore.save(commentToSave)
        await waitForExpectations([waitForSync], timeout: TestCommonConstants.networkTimeout)
        return savedComment
    }

    func savePost(_ post: Post8? = nil, withBlog blog: Blog8? = nil) async throws -> Post8? {
        let postToSave: Post8
        if let post = post {
            postToSave = post
        } else {
            postToSave = Post8(name: "name", randomId: "randomId", blog: blog)
        }

        let waitForSync = asyncExpectation(description: "synced")
        token = Amplify.Hub.listen(to: .dataStore) { payload in
            let event = DataStoreHubEvent(payload: payload)
            switch event {
            case .syncReceived(let mutationEvent):
                if mutationEvent.modelId == postToSave.id {
                    Task { await waitForSync.fulfill() }
                    if let token = self.token {
                        Amplify.Hub.removeListener(token)
                    }
                }
            default:
                break
            }
        }
        let savedPost = try await Amplify.DataStore.save(postToSave)
        await waitForExpectations([waitForSync], timeout: TestCommonConstants.networkTimeout)
        return savedPost
    }

    func saveBlog(_ blog: Blog8? = nil) async throws -> Blog8? {
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

        let waitForSync = asyncExpectation(description: "synced")
        token = Amplify.Hub.listen(to: .dataStore) { payload in
            let event = DataStoreHubEvent(payload: payload)
            switch event {
            case .syncReceived(let mutationEvent):
                if mutationEvent.modelId == blogToSave.id {
                    Task { await waitForSync.fulfill() }
                    if let token = self.token {
                        Amplify.Hub.removeListener(token)
                    }
                }

            default:
                break
            }
        }
        let savedBlog = try await Amplify.DataStore.save(blogToSave)
        await waitForExpectations([waitForSync], timeout: TestCommonConstants.networkTimeout)
        return savedBlog
    }

    func queryComment(id: String) async throws -> Comment8? {
        try await Amplify.DataStore.query(Comment8.self, byId: id)
    }

    func queryPost(id: String) async throws -> Post8? {
        try await Amplify.DataStore.query(Post8.self, byId: id)
    }

    func queryBlog(id: String) async throws -> Blog8? {
        try await Amplify.DataStore.query(Blog8.self, byId: id)
    }
}
