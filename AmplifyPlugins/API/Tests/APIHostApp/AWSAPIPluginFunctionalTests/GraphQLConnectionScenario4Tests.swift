//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
@testable import Amplify
#if os(watchOS)
@testable import APIWatchApp
#else
@testable import APIHostApp
#endif

/*
 (Belongs to) A connection that is bi-directional by adding a many-to-one connection to the type that already have a one-to-many connection.
 ```
 type Post4 @model {
   id: ID!
   title: String!
   comments: [Comment4] @connection(keyName: "byPost4", fields: ["id"])
 }

 type Comment4 @model
   @key(name: "byPost4", fields: ["postID", "content"]) {
   id: ID!
   postID: ID!
   content: String!
   post: Post4 @connection(fields: ["postID"])
 }
 ```
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details
 */
class GraphQLConnectionScenario4Tests: XCTestCase {

    override func setUp() {
        do {
            Amplify.Logging.logLevel = .verbose
            try Amplify.add(plugin: AWSAPIPlugin())

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLModelBasedTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: Comment4.self)
            ModelRegistry.register(modelType: Post4.self)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() async throws {
        await Amplify.reset()
    }

    func testCreateCommentAndGetCommentWithPost() async throws {
        guard let post = try await createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let comment = try await createComment(content: "content", post: post) else {
            XCTFail("Could not create comment")
            return
        }

        let result = try await Amplify.API.query(request: .get(Comment4.self, byId: comment.id))
        switch result {
        case .success(let queriedCommentOptional):
            guard let queriedComment = queriedCommentOptional else {
                XCTFail("Could not get comment")
                return
            }
            XCTAssertEqual(queriedComment.id, comment.id)
            XCTAssertEqual(queriedComment.post, post)
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
    }

    func testGetPostThenFetchComments() async throws {
        guard let post = try await createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard try await createComment(content: "content", post: post) != nil else {
            XCTFail("Could not create comment")
            return
        }

        guard try await createComment(content: "content", post: post) != nil else {
            XCTFail("Could not create comment")
            return
        }

        let getPostCompleted = expectation(description: "get post complete")
        let fetchCommentsCompleted = expectation(description: "fetch comments complete")
        var results: List<Comment4>?
        let response = try await Amplify.API.query(request: .get(Post4.self, byId: post.id))
        switch response {
        case .success(let queriedPostOptional):
            guard let queriedPost = queriedPostOptional else {
                XCTFail("Could not get post")
                return
            }
            XCTAssertEqual(queriedPost.id, post.id)
            getPostCompleted.fulfill()
            guard let comments = queriedPost.comments else {
                XCTFail("Could not get comments")
                return
            }
            try await comments.fetch()
            results = comments
            fetchCommentsCompleted.fulfill()
            
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
        wait(for: [getPostCompleted, fetchCommentsCompleted], timeout: TestCommonConstants.networkTimeout)
        guard var subsequentResults = results else {
            XCTFail("Could not get first results")
            return
        }
        var resultsArray: [Comment4] = []
        resultsArray.append(contentsOf: subsequentResults)
        while subsequentResults.hasNextPage() {
            let listResult = try await subsequentResults.getNextPage()
            subsequentResults = listResult
            resultsArray.append(contentsOf: subsequentResults)
        }
        XCTAssertEqual(resultsArray.count, 2)
    }

    func testUpdateComment() async throws {
        guard let post = try await createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard var comment = try await createComment(content: "content", post: post) else {
            XCTFail("Could not create comment")
            return
        }
        guard let anotherPost = try await createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        comment.post = anotherPost
        let result = try await Amplify.API.mutate(request: .update(comment))
        switch result {
        case .success(let updatedComment):
            XCTAssertEqual(updatedComment.post, anotherPost)
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
    }

    func testDeleteAndGetComment() async throws {
        guard let post = try await createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let comment = try await createComment(content: "content", post: post) else {
            XCTFail("Could not create comment")
            return
        }

        let result = try await Amplify.API.mutate(request: .delete(comment))
        switch result {
        case .success(let deletedComment):
            XCTAssertEqual(deletedComment.post, post)
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
        let result2 = try await Amplify.API.query(request: .get(Comment4.self, byId: comment.id))
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

    func testListCommentsByPostID() async throws {
        guard let post = try await createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard try await createComment(content: "content", post: post) != nil else {
            XCTFail("Could not create comment")
            return
        }
        let predicate = Comment4.keys.post.eq(post.id)
        let result = try await Amplify.API.query(request: .list(Comment4.self, where: predicate))
        switch result {
        case .success:
            break
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
    }

    func testPaginatedListCommentsByPostID() async throws {
        guard let post = try await createPost(title: "title"),
              try await createComment(content: "content", post: post) != nil,
              try await createComment(content: "content", post: post) != nil else {
            XCTFail("Could not create post and two comments")
            return
        }
        let predicate = field("postID").eq(post.id)
        var results: List<Comment4>?
        let result = try await Amplify.API.query(request: .list(Comment4.self, where: predicate, limit: 1))
        switch result {
        case .success(let comments):
            results = comments
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
        guard var subsequentResults = results else {
            XCTFail("Could not get first results")
            return
        }
        var resultsArray: [Comment4] = []
        resultsArray.append(contentsOf: subsequentResults)
        while subsequentResults.hasNextPage() {
            let listResult = try await subsequentResults.getNextPage()
            subsequentResults = listResult
            resultsArray.append(contentsOf: subsequentResults)
        }
        XCTAssertEqual(resultsArray.count, 2)
    }

    func createPost(id: String = UUID().uuidString, title: String) async throws -> Post4? {
        let post = Post4(id: id, title: title)
        let data = try await Amplify.API.mutate(request: .create(post))
        switch data {
        case .success(let post):
            return post
        case .failure(let error):
            throw error
        }
    }
    
    func createComment(id: String = UUID().uuidString, content: String, post: Post4) async throws -> Comment4? {
        let comment = Comment4(id: id, content: content, post: post)
        let data = try await Amplify.API.mutate(request: .create(comment))
        switch data {
        case .success(let comment):
            return comment
        case .failure(let error):
            throw error
        }
    }
}

extension Post4: Equatable {
    public static func == (lhs: Post4,
                           rhs: Post4) -> Bool {
        return lhs.id == rhs.id
            && lhs.title == rhs.title
    }
}
