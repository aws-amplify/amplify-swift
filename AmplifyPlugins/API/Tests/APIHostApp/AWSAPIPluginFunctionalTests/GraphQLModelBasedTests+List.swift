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

extension GraphQLModelBasedTests {

    /// Test paginated list query returns a List containing pagination functionality. This test also aggregates page
    /// results by appending to an in-memory Array, useful to backing UI components which.
    ///
    /// - Given: Two posts, and a query with the predicate for the two posts and a limit of 1
    /// - When:
    ///    - first query returns a List that provides Paginatable methods, and contains next page.
    ///    - subsequent queries exhaust the results from the API to retrieve the remaining results
    /// - Then:
    ///    - the in-memory Array is a populated with all expected items.
    func testPaginatedListFetch() async throws {
        var resultsArray: [Post] = []
        let uuid1 = UUID().uuidString
        let uuid2 = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        let post1 = Post(id: uuid1, title: title, content: "content", createdAt: .now())
        _ = try await Amplify.API.mutate(request: .create(post1))
        let post2 = Post(id: uuid2, title: title, content: "content", createdAt: .now())
        _ = try await Amplify.API.mutate(request: .create(post2))

        let post = Post.keys
        let predicate = post.id == uuid1 || post.id == uuid2
        var results: List<Post>?
        let response = try await Amplify.API.query(request: .list(Post.self, where: predicate, limit: 1))
        
        guard case .success(let graphQLresponse) = response else {
            XCTFail("Missing successful response")
            return
        }
        results = graphQLresponse
        guard var subsequentResults = results else {
            XCTFail("Could not get first results")
            return
        }

        resultsArray.append(contentsOf: subsequentResults)

        while subsequentResults.hasNextPage() {
            let listResult = try await subsequentResults.getNextPage()
            subsequentResults = listResult
            resultsArray.append(contentsOf: subsequentResults)
        }
        XCTAssertEqual(resultsArray.count, 2)
    }

    /// Test paginated list query returns a List containing pagination functionality.
    ///
    /// - Given: Two posts, and a query with the predicate, exhausted `getNextPage` calls
    /// - When:
    ///    - A `getNextPage` is made when `hasNextPage` returns false.
    /// - Then:
    ///    - A validation error is returned
    func testPaginatedListFetchValidationError() async throws{
        let uuid1 = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        let createdPost = Post(id: uuid1, title: title, content: "content", createdAt: .now())
        _ = try await Amplify.API.mutate(request: .create(createdPost))

        let post = Post.keys
        let predicate = post.id == uuid1
        var results: List<Post>?
        let request: GraphQLRequest<List<Post>> = GraphQLRequest<Post>.list(Post.self, where: predicate)
        let response = try await Amplify.API.query(request: request)

        guard case .success(let graphQLResponse) = response else {
            XCTFail("Missing successful response")
            return
        }

        results = graphQLResponse
        guard var subsequentResults = results else {
            XCTFail("Could not get first results")
            return
        }
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

    /// This test shows the issue with retrieving comments by postId. The schema used to create `Post.swift` and
    /// `Comment.swift` provisions an AppSync API that does not provide a list query operation for comments by postId.
    ///
    /// - Given: A post with a comment, query for the post, and traverse to the comments
    /// - When:
    ///    - `comments.fetch` is called
    /// - Then:
    ///    - `CoreError` is returned
    func testFetchListOfCommentsFromPostFails() async throws {
        let uuid1 = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        let post = Post(id: uuid1, title: title, content: "content", createdAt: .now())
        _ = try await Amplify.API.mutate(request: .create(post))
        let comment = Comment(id: uuid1, content: "content", createdAt: .now(), post: post)
        _ = try await Amplify.API.mutate(request: .create(comment))
        var results: Post?
        let response = try await Amplify.API.query(request: .get(Post.self, byId: post.id))
        
        guard case .success(let graphQLResponse) = response else {
            XCTFail("Missing successful response")
            return
        }
        results = graphQLResponse

        guard let retrievedPost = results else {
            XCTFail("Could not get post")
            return
        }
        
        do {
            try await retrievedPost.comments?.fetch()
            XCTFail("Should have failed to fetch")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
