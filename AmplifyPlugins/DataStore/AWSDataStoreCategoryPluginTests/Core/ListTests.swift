//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class ListTests: BaseDataStoreTests {

    /// - Given: a list a `Post` and a few comments associated with it
    /// - When:
    ///   - the `post.comments` is accessed synchronously
    /// - Then:
    ///   - the list should be correctly loaded and populated
    func testSynchronousLazyLoad() {
        let postId = preparePostDataForTest()
        let expect = expectation(description: "a lazy list should return the correct results")
        Amplify.DataStore.query(Post.self, byId: postId) {
            defer { expect.fulfill() }
            switch $0 {
            case .success(let result):
                if let post = result {
                    if let comments = post.comments {
                        guard case .notLoaded = comments.loadedState else {
                            XCTFail("Should not be loaded")
                            return
                        }
                        XCTAssertEqual(comments.count, 2)
                        guard case .loaded = comments.loadedState else {
                            XCTFail("Should be loaded")
                            return
                        }
                    } else {
                        XCTFail("post.comments should not be nil")
                    }
                } else {
                    XCTFail("Failed to query recently saved post by id")
                }
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }

        wait(for: [expect], timeout: 5)
    }

    /// - Given: a list a `Post` and a few comments associated with it
    /// - When:
    ///   - the `post.comments` is accessed asynchronously with a callback
    /// - Then:
    ///   - the list should be correctly loaded and populated
    func testAsynchronousLazyLoadWithCallback() {
        let postId = preparePostDataForTest()
        let expect = expectation(description: "a lazy list should return the correct results")
        func checkComments(_ comments: List<Comment>) {
            guard case .notLoaded = comments.loadedState else {
                XCTFail("Should not be loaded")
                return
            }
            comments.load {
                switch $0 {
                case .success(let loadedComments):
                    guard case .loaded = comments.loadedState else {
                        XCTFail("Should be loaded")
                        return
                    }
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
                if let post = result, let comments = post.comments {
                    checkComments(comments)
                } else {
                    XCTFail("Failed to query recently saved post by id")
                }
            case .failure(let error):
                XCTFail(error.errorDescription)
                expect.fulfill()
            }
        }

        wait(for: [expect], timeout: 5)
    }

    /// - Given: a list a `Post` and a few comments associated with it
    /// - When:
    ///   - the `post.comments` is accessed asynchronously using the Combine integration
    /// - Then:
    ///   - the list should be correctly loaded and populated through a `Publisher`
    func testAsynchronousLazyLoadWithCombine() {
        let postId = preparePostDataForTest()
        let expect = expectation(description: "a lazy list should return the correct results")
        func checkComments(_ comments: List<Comment>) {
            guard case .notLoaded = comments.loadedState else {
                XCTFail("Should not be loaded")
                return
            }
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
                    guard case .loaded = comments.loadedState else {
                        XCTFail("Should be loaded")
                        return
                    }
                    XCTAssertEqual(loadedComments.count, 2)
                }
            )
        }

        Amplify.DataStore.query(Post.self, byId: postId) {
            switch $0 {
            case .success(let result):
                if let post = result, let comments = post.comments {
                    checkComments(comments)
                } else {
                    XCTFail("Failed to query recently saved post by id")
                }
            case .failure(let error):
                XCTFail(error.errorDescription)
                expect.fulfill()
            }
        }

        wait(for: [expect], timeout: 5)
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
