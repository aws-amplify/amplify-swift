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
 (HasMany) A Post that can have many comments
 ```
 type Post3 @model {
   id: ID!
   title: String!
   comments: [Comment3] @connection(keyName: "byPost3", fields: ["id"])
 }

 type Comment3 @model
   @key(name: "byPost3", fields: ["postID", "content"]) {
   id: ID!
   postID: ID!
   content: String!
 }
 ```
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details
 */
class GraphQLConnectionScenario3Tests: XCTestCase {

    override func setUp() async throws {
        do {
            Amplify.Logging.logLevel = .verbose
            try Amplify.add(plugin: AWSAPIPlugin())

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLModelBasedTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: Comment3.self)
            ModelRegistry.register(modelType: Post3.self)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() async throws {
        await Amplify.reset()
        try await Task.sleep(seconds: 1)
    }

    func testQuerySinglePost() async throws {
        guard let post = try await createPost(title: "title") else {
            XCTFail("Failed to set up test")
            return
        }

        let graphQLResponse = try await Amplify.API.query(request: .get(Post3.self, byId: post.id))
        guard case let .success(data) = graphQLResponse else {
            XCTFail("Missing successful response")
            return
        }
        guard let resultPost = data else {
            XCTFail("Missing post from query")
            return
        }
        XCTAssertEqual(resultPost.id, post.id)
    }

    // Create a post and a comment for the post
    // Retrieve the comment and ensure that the comment is associated with the correct post
    func testCreatAndGetComment() async throws {
        guard let post = try await createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let comment = try await createComment(postID: post.id, content: "content") else {
            XCTFail("Could not create comment")
            return
        }

        let result = try await Amplify.API.query(request: .get(Comment3.self, byId: comment.id))
        switch result {
        case .success(let queriedCommentOptional):
            guard let queriedComment = queriedCommentOptional else {
                XCTFail("Could not get comment")
                return
            }
            XCTAssertEqual(queriedComment.id, comment.id)
            XCTAssertEqual(queriedComment.postID, post.id)
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
    }

    // Create a post and a comment associated with that post.
    // Create another post that will be used to update the existing comment
    // Update the existing comment to point to the other post
    // Expect that the queried comment is associated with the other post
    func testUpdateComment() async throws {
        guard let post = try await createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard var comment = try await createComment(postID: post.id, content: "content") else {
            XCTFail("Could not create comment")
            return
        }
        guard let anotherPost = try await createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        comment.postID = anotherPost.id
        let result = try await Amplify.API.mutate(request: .update(comment))
        switch result {
        case .success(let updatedComment):
            XCTAssertEqual(updatedComment.postID, anotherPost.id)
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
    }

    func testUpdateExistingPost() async throws {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard var post = try await createPost(id: uuid, title: title) else {
            XCTFail("Failed to ensure at least one Post to be retrieved on the listQuery")
            return
        }
        let updatedTitle = title + "Updated"
        post.title = updatedTitle
        let data = try await Amplify.API.mutate(request: .update(post))
        switch data {
        case .success(let post):
            XCTAssertEqual(post.title, updatedTitle)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }

    func testDeleteExistingPost() async throws {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let post = try await createPost(id: uuid, title: title) else {
            XCTFail("Could not create post")
            return
        }

        let data = try await Amplify.API.mutate(request: .delete(post))
        switch data {
        case .success(let post):
            XCTAssertEqual(post.title, title)
        case .failure(let error):
            XCTFail("\(error)")
        }
        let graphQLResponse = try await Amplify.API.query(request: .get(Post3.self, byId: uuid))
        guard case let .success(post) = graphQLResponse else {
            XCTFail("Missing successful response")
            return
        }
        XCTAssertNil(post)
    }

    // Create a post and then create a comment associated with the post
    // Delete the comment and then query for the comment
    // Expected query should return `nil` comment
    func testDeleteAndGetComment() async throws {
        guard let post = try await createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let comment = try await createComment(postID: post.id, content: "content") else {
            XCTFail("Could not create comment")
            return
        }

        let result = try await Amplify.API.mutate(request: .delete(comment))
        switch result {
        case .success(let deletedComment):
            XCTAssertEqual(deletedComment.postID, post.id)
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
        let result2 = try await Amplify.API.query(request: .get(Comment3.self, byId: comment.id))
        switch result2 {
        case .success(let comment):
            guard comment == nil else {
                XCTFail("Should be nil after deletion")
                return
            }
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
    }
}
