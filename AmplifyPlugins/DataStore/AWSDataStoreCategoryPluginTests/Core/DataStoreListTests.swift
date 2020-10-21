//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import XCTest
@testable import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class DataStoreListTests: BaseDataStoreTests {

    /// - Given: a list a `Post` and a few comments associated with it
    /// - When:
    ///   - the `post.comments` is accessed synchronously
    /// - Then:
    ///   - the list should be correctly loaded and populated
    func testSynchronousLazyLoad() {
        let expect = expectation(description: "a lazy list should return the correct results")

        let postId = preparePostDataForTest()

        Amplify.DataStore.query(Post.self, byId: postId) {
            switch $0 {
            case .success(let result):
                if let post = result, let postComments = post.comments {
                    if let comments = postComments as? DataStoreList<Comment> {
                        XCTAssert(comments.state == .pending)
                        XCTAssertEqual(comments.count, 2)
                        XCTAssert(comments.state == .loaded)
                    } else {
                        XCTFail("Failed to cast to DataStoreList")
                    }
                } else {
                    XCTFail("Failed to query recently saved post by id")
                }
                expect.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
                expect.fulfill()
            }
        }

        wait(for: [expect], timeout: 1)
    }

    /// - Given: a list a `Post` and a few comments associated with it
    /// - When:
    ///   - the `post.comments` is accessed asynchronously with a callback
    /// - Then:
    ///   - the list should be correctly loaded and populated
    func testAsynchronousLazyLoadWithCallback() {
        let expect = expectation(description: "a lazy list should return the correct results")

        let postId = preparePostDataForTest()

        func checkComments(_ comments: DataStoreList<Comment>) {
            XCTAssert(comments.state == .pending)
            comments.load {
                switch $0 {
                case .success(let loadedComments):
                    XCTAssert(comments.state == .loaded)
                    XCTAssertEqual(loadedComments.count, 2)
                    expect.fulfill()
                case .failure(let error):
                    XCTFail(error.errorDescription)
                    expect.fulfill()
                }
            }
        }

        Amplify.DataStore.query(Post.self, byId: postId) {
            switch $0 {
            case .success(let result):
                if let post = result,
                   let postComments = post.comments,
                   let comments = postComments as? DataStoreList<Comment> {
                    checkComments(comments)
                } else {
                    XCTFail("Failed to query recently saved post by id")
                }
            case .failure(let error):
                XCTFail(error.errorDescription)
                expect.fulfill()
            }
        }

        wait(for: [expect], timeout: 1)
    }

    /// - Given: a list a `Post` and a few comments associated with it
    /// - When:
    ///   - the `post.comments` is accessed asynchronously using the Combine integration
    /// - Then:
    ///   - the list should be correctly loaded and populated through a `Publisher`
    func testAsynchronousLazyLoadWithCombine() {
        let expect = expectation(description: "a lazy list should return the correct results")

        let postId = preparePostDataForTest()

        func checkComments(_ comments: DataStoreList<Comment>) {
            XCTAssert(comments.state == .pending)
            _ = comments.loadAsPublisher().sink(
                receiveCompletion: {
                    switch $0 {
                    case .finished:
                        expect.fulfill()
                    case .failure(let error):
                        XCTFail(error.errorDescription)
                        expect.fulfill()
                    }
                },
                receiveValue: { loadedComments in
                    XCTAssert(comments.state == .loaded)
                    XCTAssertEqual(loadedComments.count, 2)
                }
            )
        }

        Amplify.DataStore.query(Post.self, byId: postId) {
            switch $0 {
            case .success(let result):
                if let post = result,
                   let postComments = post.comments,
                   let comments = postComments as? DataStoreList<Comment> {
                    checkComments(comments)
                } else {
                    XCTFail("Failed to query recently saved post by id")
                }
            case .failure(let error):
                XCTFail(error.errorDescription)
                expect.fulfill()
            }
        }

        wait(for: [expect], timeout: 1)
    }

    // MARK: - Helpers

    func preparePostDataForTest() -> Model.Identifier {
        let post = Post(title: "title", content: "content", createdAt: .now())
        populateData([post])
        populateData([
            Comment(content: "Comment 1", createdAt: .now(), post: post),
            Comment(content: "Comment 2", createdAt: .now(), post: post)
        ])
        return post.id
    }
}
