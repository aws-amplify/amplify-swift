//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class SQLiteStorageEngineAdapterTests: BaseDataStoreTests {

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post)` is called
    /// - Then:
    ///   - call `query(Post)` to check if the model was correctly inserted
    func testInsertPost() {
        let expectation = self.expectation(
            description: "it should save and select a Post from the database")

        // insert a post
        let post = Post(title: "title", content: "content", createdAt: Date())
        storageAdapter.save(post) { saveResult in
            switch saveResult {
            case .success:
                storageAdapter.query(Post.self) { queryResult in
                    switch queryResult {
                    case .success(let posts):
                        XCTAssert(posts.count == 1)
                        if let post = posts.first {
                            XCTAssert(post.id == post.id)
                            XCTAssert(post.title == post.title)
                            XCTAssert(post.content == post.content)
                        }
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail(String(describing: error))
                        expectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post)` is called
    /// - Then:
    ///   - call `query(Post, where: title == post.title)` to check
    ///   if the model was correctly inserted using a predicate
    func testInsertPostAndSelectByTitle() {
        let expectation = self.expectation(
            description: "it should save and select a Post from the database")

        // insert a post
        let post = Post(title: "title", content: "content", createdAt: Date())
        storageAdapter.save(post) { saveResult in
            switch saveResult {
            case .success:
                let predicate = Post.keys.title == post.title
                storageAdapter.query(Post.self, predicate: predicate) { queryResult in
                    switch queryResult {
                    case .success(let posts):
                        XCTAssertEqual(posts.count, 1)
                        if let post = posts.first {
                            XCTAssert(post.id == post.id)
                            XCTAssert(post.title == post.title)
                            XCTAssert(post.content == post.content)
                        }
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail(String(describing: error))
                        expectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post)` is called
    /// - Then:
    ///   - call `save(post)` again with an updated title
    ///   - check if the `query(Post)` returns only 1 post
    ///   - the post has the updated title
    func testInsertPostAndThenUpdateIt() {
        let expectation = self.expectation(
            description: "it should insert and update a Post")

        func checkSavedPost(id: String) {
            storageAdapter.query(Post.self) {
                switch $0 {
                case .success(let posts):
                    XCTAssertEqual(posts.count, 1)
                    if let post = posts.first {
                        XCTAssertEqual(post.id, id)
                        XCTAssertEqual(post.title, "title updated")
                    }
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail(String(describing: error))
                    expectation.fulfill()
                }
            }
        }

        var post = Post(title: "title", content: "content", createdAt: Date())
        storageAdapter.save(post) { insertResult in
            switch insertResult {
            case .success:
                post.title = "title updated"
                storageAdapter.save(post) { updateResult in
                    switch updateResult {
                    case .success:
                        checkSavedPost(id: post.id)
                    case .failure(let error):
                        XCTFail(error.errorDescription)
                    }
                }
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    /// - Given: a list a `Post` instance
    /// - When:
    ///   - the `save(post)` is called
    /// - Then:
    ///   - call `delete(Post, id)` and check if `query(Post)` is empty
    ///   - check if `storageAdapter.exists(Post, id)` returns `false`
    func testInsertPostAndThenDeleteIt() {
        let expectation = self.expectation(description: "it should insert and update a Post")

        func checkDeletedPost(id: String) {
            storageAdapter.query(Post.self) {
                switch $0 {
                case .success(let posts):
                    XCTAssertEqual(posts.count, 0)
                    do {
                        let exists = try storageAdapter.exists(Post.self, withId: id)
                        XCTAssertFalse(exists)
                    } catch {
                        XCTFail(String(describing: error))
                    }
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail(String(describing: error))
                    expectation.fulfill()
                }
            }
        }

        let post = Post(title: "title", content: "content", createdAt: Date())
        storageAdapter.save(post) { insertResult in
            switch insertResult {
            case .success:
                storageAdapter.delete(Post.self, withId: post.id) {
                    switch $0 {
                    case .success:
                        checkDeletedPost(id: post.id)
                    case .failure(let error):
                        XCTFail(error.errorDescription)
                    }
                }
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)
    }

}
