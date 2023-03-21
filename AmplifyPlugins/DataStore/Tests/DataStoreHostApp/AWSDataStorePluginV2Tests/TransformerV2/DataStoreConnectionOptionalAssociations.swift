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

        let comment = try await createModelUntilSynced(data: randomComment())
        let quriedComment = try await queryComment(id: comment.id)
        XCTAssertEqual(comment.identifier, quriedComment?.identifier)
    }

    func testSavePostThenQuery() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let post = try await createModelUntilSynced(data: randomPost())
        let quiredPost = try await queryPost(id: post.id)
        XCTAssertEqual(post.identifier, quiredPost?.identifier)
    }

    func testSaveBlogThenQuery() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let blog = try await createModelUntilSynced(data: randomBlog())
        let queriedBlog = try await queryBlog(id: blog.id)
        XCTAssertEqual(blog.identifier, queriedBlog?.identifier)
    }

    func testSaveCommentThenUpdateWithPost() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        var comment = try await createModelUntilSynced(data: randomComment())
        let post = try await createModelUntilSynced(data: randomPost())
        comment.post = post
        let updatedComment = try await updateModelWaitForSync(data: comment, isEqual: { $0.identifier == $1.identifier })
        guard let queriedComment = try await queryComment(id: comment.id) else {
            XCTFail("Failed to query comment")
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
        XCTAssertEqual(firstLazyComment.id, queriedComment.id)
        XCTAssertEqual(queriedPost.comments?.count, 1)
    }

    func testSavePostThenUpdateWithBlog() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        var post = try await createModelUntilSynced(data: randomPost())
        let blog = try await createModelUntilSynced(data: randomBlog())
        post.blog = blog
        let updatedPost = try await updateModelWaitForSync(data: post, isEqual: { $0.identifier == $1.identifier })
        guard let queriedPost = try await queryPost(id: post.id) else {
            XCTFail("Failed to query post ")
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
        XCTAssertEqual(firstLazyPost.id, updatedPost.id)
        XCTAssertEqual(queriedBlog.posts?.count, 1)
    }

    func testUpdateCommentWithPostAndPostWithBlog() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        var comment = try await createModelUntilSynced(data: randomComment())
        var post = try await createModelUntilSynced(data: randomPost())
        let blog = try await createModelUntilSynced(data: randomBlog())

        comment.post = post
        post.blog = blog
        let updatedPost = try await updateModelWaitForSync(data: post, isEqual: { $0.identifier == $1.identifier })
        let updatedComment = try await updateModelWaitForSync(data: comment, isEqual: { $0.identifier == $1.identifier })
        guard let queriedComment = try await queryComment(id: updatedComment.id) else {
            XCTFail("Failed to query comment!")
            return
        }
        XCTAssertNotNil(queriedComment.post)
        XCTAssertEqual(queriedComment.post?.id, updatedPost.id)
        XCTAssertNotNil(queriedComment.post?.blog)
        XCTAssertEqual(queriedComment.post?.blog?.id, blog.id)
    }

    func testRemovePostFromCommentAndBlogFromPost() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let blog = try await createModelUntilSynced(data: randomBlog())
        let post = try await createModelUntilSynced(data: randomPost(with: blog))
        let comment = try await createModelUntilSynced(data: randomComment(with: post))

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
        let request = GraphQLRequest<Comment8>.updateMutation(of: queriedComment, version: 1)
        guard let variables = request.variables,
              let input = variables["input"] as? [String: Any?],
              let postValue = input["postId"],
              postValue == nil else {
            XCTFail("Failed to retrieve input object from GraphQL variables")
            return
        }

        try await updateModelWaitForSync(data: queriedComment, isEqual: { lhs, rhs in
            lhs.identifier == rhs.identifier
        })

        guard let queriedCommentWithoutPost = try await queryComment(id: comment.id) else {
            XCTFail("Failed to query comment without post")
            return
        }
        
        XCTAssertNil(queriedCommentWithoutPost.post)
        
        queriedPost.blog = nil
        try await updateModelWaitForSync(data: queriedPost, isEqual: { lhs, rhs in
            lhs.identifier == rhs.identifier
        })
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

    func randomComment(with post: Post8? = nil) -> Comment8 {
        Comment8(content: UUID().uuidString, post: post)
    }

    func randomBlog() -> Blog8 {
        let notes = [UUID().uuidString, UUID().uuidString]
        let nestedModel = MyNestedModel8(id: UUID().uuidString,
                                         nestedName: UUID().uuidString,
                                         notes: notes)
        let customModel = MyCustomModel8(id: UUID().uuidString,
                                         name: UUID().uuidString,
                                         desc: UUID().uuidString,
                                         children: [nestedModel])
        return Blog8(name: UUID().uuidString, customs: [customModel], notes: notes)
    }

    func randomPost(with blog: Blog8? = nil ) -> Post8 {
        Post8(name: UUID().uuidString, blog: blog)
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
