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
extension GraphQLConnectionScenario3Tests {

    func testGetPostThenIterateComments() async throws {
        guard let post = try await createPost(title: "title"),
             try await createComment(postID: post.id, content: "content") != nil,
             try await createComment(postID: post.id, content: "content") != nil else {
            XCTFail("Could not create post and two comments")
            return
        }

        let getPostCompleted = expectation(description: "get post complete")
        var results: List<Comment3>?
        Amplify.API.query(request: .get(Post3.self, byId: post.id)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let queriedPostOptional):
                    guard let queriedPost = queriedPostOptional else {
                        XCTFail("Could not get post")
                        return
                    }
                    XCTAssertEqual(queriedPost.id, post.id)
                    results = queriedPost.comments
                    getPostCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getPostCompleted], timeout: TestCommonConstants.networkTimeout)
        guard var comments = results else {
            XCTFail("Could not get comments")
            return
        }
        var resultsArray: [Comment3] = []
        let fetchSuccess = expectation(description: "Fetch successful")
        try await comments.fetch()
        fetchSuccess.fulfill()
        wait(for: [fetchSuccess], timeout: TestCommonConstants.networkTimeout)
        for comment in comments {
            resultsArray.append(comment)
        }
        while comments.hasNextPage() {
            let getNextPageSuccess = expectation(description: "Get next page successfully")
            let listResult = try await comments.getNextPage()
            comments = listResult
            resultsArray.append(contentsOf: comments)
            getNextPageSuccess.fulfill()
            wait(for: [getNextPageSuccess], timeout: TestCommonConstants.networkTimeout)
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

        let getPostCompleted = expectation(description: "get post complete")
        var results: List<Comment3>?
        Amplify.API.query(request: .get(Post3.self, byId: post.id)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let queriedPostOptional):
                    guard let queriedPost = queriedPostOptional else {
                        XCTFail("Could not get post")
                        return
                    }
                    XCTAssertEqual(queriedPost.id, post.id)
                    results = queriedPost.comments
                    getPostCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getPostCompleted], timeout: TestCommonConstants.networkTimeout)
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

        let requestInvokedSuccessfully = expectation(description: "request completed")

        _ = Amplify.API.query(request: .list(Post3.self)) { event in
            switch event {
            case .success(let graphQLResponse):
                guard case let .success(posts) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                XCTAssertTrue(!posts.isEmpty)
                print(posts)
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("Unexpected .failed event: \(error)")
            }
        }

        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
    }

    func testListPostWithPredicate() async throws {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let uniqueTitle = testMethodName + uuid + "Title"
        guard let createdPost = try await createPost(id: uuid, title: uniqueTitle) else {
            XCTFail("Failed to ensure at least one Post to be retrieved on the listQuery")
            return
        }

        let requestInvokedSuccessfully = expectation(description: "request completed")
        let post = Post3.keys
        let predicate = post.id == uuid && post.title == uniqueTitle
        _ = Amplify.API.query(request: .list(Post3.self, where: predicate)) { event in
            switch event {
            case .success(let graphQLResponse):
                guard case let .success(posts) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                XCTAssertEqual(posts.count, 1)
                guard let singlePost = posts.first else {
                    XCTFail("Should only have a single post with the unique title")
                    return
                }
                XCTAssertEqual(singlePost.id, uuid)
                XCTAssertEqual(singlePost.title, uniqueTitle)
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("Unexpected .failed event: \(error)")
            }
        }

        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
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
        let listCommentByPostIDCompleted = expectation(description: "list projects completed")
        let predicate = Comment3.keys.postID.eq(post.id)
        Amplify.API.query(request: .list(Comment3.self, where: predicate)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let comments):
                    print(comments)
                    listCommentByPostIDCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listCommentByPostIDCompleted], timeout: TestCommonConstants.networkTimeout)
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
        let listCommentByPostIDCompleted = expectation(description: "list projects completed")
        var results: List<Comment3>?
        let predicate = Comment3.keys.postID.eq(post.id)
        Amplify.API.query(request: .list(Comment3.self, where: predicate, limit: 1)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let comments):
                    results = comments
                    listCommentByPostIDCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listCommentByPostIDCompleted], timeout: TestCommonConstants.networkTimeout)
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

        let firstQueryCompleted = expectation(description: "first query completed")
        let post = Post3.keys
        let predicate = post.id == uuid1
        var results: List<Post3>?
        let request: GraphQLRequest<List<Post3>> = GraphQLRequest<Post3>.list(Post3.self, where: predicate)
        _ = Amplify.API.query(request: request) { event in
            switch event {
            case .success(let response):
                guard case let .success(graphQLResponse) = response else {
                    XCTFail("Missing successful response")
                    return
                }

                results = graphQLResponse
                firstQueryCompleted.fulfill()
            case .failure(let error):
                XCTFail("Unexpected .failure event: \(error)")
            }
        }

        wait(for: [firstQueryCompleted], timeout: TestCommonConstants.networkTimeout)
        guard var subsequentResults = results else {
            XCTFail("Could not get first results")
            return
        }
        while subsequentResults.hasNextPage() {
            let listResult = try await subsequentResults.getNextPage()
            subsequentResults = listResult
        }
        XCTAssertFalse(subsequentResults.hasNextPage())
        let invalidFetchCompleted = expectation(description: "fetch completed with validation error")
        do {
            let listResult = try await subsequentResults.getNextPage()
            XCTFail("Unexpected \(listResult)")
        } catch let coreError as CoreError {
            guard case .clientValidation = coreError else {
                XCTFail("Unexpected CoreError \(coreError)")
                return
            }
            invalidFetchCompleted.fulfill()
        }
        
        wait(for: [invalidFetchCompleted], timeout: TestCommonConstants.networkTimeout)
    }
}
