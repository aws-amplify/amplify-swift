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
extension GraphQLConnectionScenario3Tests {

    func testGetPostThenIterateComments() async throws {
        guard let post = try await createPost(title: "title"),
             try await createComment(postID: post.id, content: "content") != nil,
             try await createComment(postID: post.id, content: "content") != nil else {
            XCTFail("Could not create post and two comments")
            return
        }

        var results: List<Comment3>?
        let result = try await Amplify.API.query(request: .get(Post3.self, byId: post.id))
        switch result {
        case .success(let queriedPostOptional):
            guard let queriedPost = queriedPostOptional else {
                XCTFail("Could not get post")
                return
            }
            XCTAssertEqual(queriedPost.id, post.id)
            results = queriedPost.comments
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
        guard var comments = results else {
            XCTFail("Could not get comments")
            return
        }
        var resultsArray: [Comment3] = []
        try await comments.fetch()
        for comment in comments {
            resultsArray.append(comment)
        }
        while comments.hasNextPage() {
            let listResult = try await comments.getNextPage()
            comments = listResult
            resultsArray.append(contentsOf: comments)
        }
        XCTAssertEqual(resultsArray.count, 2)
    }

    func testGetPostThenFetchComments() async throws {
        guard let post = try await createPost(title: "title"),
              try await createComment(postID: post.id, content: "content") != nil,
              try await createComment(postID: post.id, content: "content") != nil else {
            XCTFail("Could not create post and two comments")
            return
        }

        var results: List<Comment3>?
        let result = try await Amplify.API.query(request: .get(Post3.self, byId: post.id))
        switch result {
        case .success(let queriedPostOptional):
            guard let queriedPost = queriedPostOptional else {
                XCTFail("Could not get post")
                return
            }
            XCTAssertEqual(queriedPost.id, post.id)
            results = queriedPost.comments
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
        guard var comments = results else {
            XCTFail("Could not get comments")
            return
        }
        var resultsArray: [Comment3] = []
        try await comments.fetch()
        resultsArray.append(contentsOf: comments)
        while comments.hasNextPage() {
            let listResult = try await comments.getNextPage()
            comments = listResult
            resultsArray.append(contentsOf: comments)
        }
        XCTAssertEqual(resultsArray.count, 2)
    }

    // Create a post and list the posts
    func testListPost() async throws {
        guard try await createPost(title: "title") != nil else {
            XCTFail("Failed to ensure at least one Post to be retrieved on the listQuery")
            return
        }

        let graphQLResponse = try await Amplify.API.query(request: .list(Post3.self))
        guard case let .success(posts) = graphQLResponse else {
            XCTFail("Missing successful response")
            return
        }
        XCTAssertTrue(!posts.isEmpty)
    }

    func testListPostWithPredicate() async throws {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let uniqueTitle = testMethodName + uuid + "Title"
        guard try await createPost(id: uuid, title: uniqueTitle) != nil else {
            XCTFail("Failed to ensure at least one Post to be retrieved on the listQuery")
            return
        }

        let post = Post3.keys
        let predicate = post.id == uuid && post.title == uniqueTitle
        let graphQLResponse = try await Amplify.API.query(request: .list(Post3.self, where: predicate, limit: 1000))
        guard case var .success(posts) = graphQLResponse else {
            XCTFail("Missing successful response")
            return
        }
        
        while posts.count == 0 && posts.hasNextPage() {
            posts = try await posts.getNextPage()
        }
        XCTAssertEqual(posts.count, 1)
        guard let singlePost = posts.first else {
            XCTFail("Should only have a single post with the unique title")
            return
        }
        XCTAssertEqual(singlePost.id, uuid)
        XCTAssertEqual(singlePost.title, uniqueTitle)
    }

    // Create a post and a comment with that post
    // list the comments by postId
    func testListCommentsByPostID() async throws {
        guard let post = try await createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard try await createComment(postID: post.id, content: "content") != nil else {
            XCTFail("Could not create comment")
            return
        }

        let predicate = Comment3.keys.postID.eq(post.id)
        guard case .success(var comments) = try await Amplify.API.query(request: .list(Comment3.self, where: predicate))
        else {
            XCTFail("Failed to retrieve comments")
            return
        }

        while comments.count == 0 && comments.hasNextPage() {
            comments = try await comments.getNextPage()
        }
        XCTAssertEqual(comments.count, 1)
    }

    /// Test paginated list query returns a List containing pagination functionality. This test also aggregates page
    /// results by appending to an in-memory Array, useful to backing UI components which.
    ///
    /// - Given: Two comments for the same post, and a query with the predicate for comments by postID with limit of 1
    /// - When:
    ///    - first query returns a List that provides Paginatable methods, and contains next page.
    ///    - subsequent queries exhaust the results from the API to retrieve the remaining results
    /// - Then:
    ///    - the in-memory Array is a populated with exactly two comments.
    func testPaginatedListCommentsByPostID() async throws {
        guard let post = try await createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard try await createComment(postID: post.id, content: "content") != nil else {
            XCTFail("Could not create comment")
            return
        }
        guard try await createComment(postID: post.id, content: "content") != nil else {
            XCTFail("Could not create comment")
            return
        }
        var results: List<Comment3>?
        let predicate = Comment3.keys.postID.eq(post.id)
        let result = try await Amplify.API.query(request: .list(Comment3.self, where: predicate, limit: 100))
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
        var resultsArray: [Comment3] = []
        resultsArray.append(contentsOf: subsequentResults)
        while subsequentResults.hasNextPage() {
            let listResult = try await subsequentResults.getNextPage()
            subsequentResults = listResult
            resultsArray.append(contentsOf: subsequentResults)
        }
        XCTAssertEqual(resultsArray.count, 2)
    }

    /// Test paginated list query returns a List containing pagination functionality. This test also aggregates page
    /// results by appending to an in-memory Array, useful to backing UI components which.
    ///
    /// - Given: Two posts, and a query with the predicate, exhausted `fetch` calls
    /// - When:
    ///    - A `fetch` is made when `hasNextPage` returns false.
    /// - Then:
    ///    - A validation error is returned
    func testPaginatedListFetchValidationError() async throws {
        let uuid1 = UUID().uuidString
        guard try await createPost(id: uuid1, title: "title") != nil else {
            XCTFail("Failed to create post")
            return
        }
        let post = Post3.keys
        let predicate = post.id == uuid1
        let request: GraphQLRequest<List<Post3>> = GraphQLRequest<Post3>.list(Post3.self, where: predicate)
        let response = try await Amplify.API.query(request: request)
        guard case let .success(graphQLResponse) = response else {
            XCTFail("Missing successful response")
            return
        }
        var subsequentResults = graphQLResponse
        while subsequentResults.hasNextPage() {
            let listResult = try await subsequentResults.getNextPage()
            subsequentResults = listResult
        }
        XCTAssertFalse(subsequentResults.hasNextPage())
        do {
            let listResult = try await subsequentResults.getNextPage()
            XCTFail("Unexpected \(listResult)")
        } catch let coreError as CoreError {
            guard case .clientValidation = coreError else {
                XCTFail("Unexpected CoreError \(coreError)")
                return
            }
        }
    }
}
