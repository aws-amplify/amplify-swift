//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class SQLiteStorageEngineAdapterTests: XCTestCase {

    var storageAdapter: SQLiteStorageEngineAdapter!

    override func setUp() {
        super.setUp()

        Amplify.reset()

        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)

        let connection = try? Connection(.inMemory)
        XCTAssertNotNil(connection)
        storageAdapter = SQLiteStorageEngineAdapter(connection: connection!)
        XCTAssertNotNil(storageAdapter)

        do {
            try storageAdapter.setUp(models: ModelRegistry.models)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    // MARK: - Utilities

    /// it should sort a `Model` collection by their dependency order
    func testModelDependencySortOrder() {
        let models: [Model.Type] = [Comment.self, Post.self]
        let sorted = models.sortByDependencyOrder()

        XCTAssert(models.count == sorted.count)
        XCTAssert(models[0].schema.name == sorted[1].schema.name)
        XCTAssert(models[1].schema.name == sorted[0].schema.name)
    }

    // MARK: - Operations

    /// it should create a table, insert a row and select it
    func testInsertPost() {
        let expectation = self.expectation(
            description: "it should save and select a Post from the database")

        // insert a post
        let post = Post(title: "title", content: "content")
        storageAdapter.save(post) { saveResult in
            switch saveResult {
            case .result:
                storageAdapter.query(Post.self) { queryResult in
                    switch queryResult {
                    case .result(let posts):
                        XCTAssert(posts.count == 1)
                        XCTAssert(posts.first!.id == post.id)
                        XCTAssert(posts.first!.title == post.title)
                        XCTAssert(posts.first!.content == post.content)
                        expectation.fulfill()
                    case .error(let error):
                        XCTFail(String(describing: error))
                        expectation.fulfill()
                    }
                }
            case .error(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    func testInsertPostAndSelectByTitle() {
        let expectation = self.expectation(
            description: "it should save and select a Post from the database")

        // insert a post
        let post = Post(title: "title", content: "content")
        storageAdapter.save(post) { saveResult in
            switch saveResult {
            case .result:
                let predicate = Post.keys.title == post.title
                storageAdapter.query(Post.self, predicate: predicate) { queryResult in
                    switch queryResult {
                    case .result(let posts):
                        XCTAssertEqual(posts.count, 1)
                        XCTAssertEqual(posts.first!.id, post.id)
                        XCTAssertEqual(posts.first!.title, post.title)
                        XCTAssertEqual(posts.first!.content, post.content)
                        expectation.fulfill()
                    case .error(let error):
                        XCTFail(String(describing: error))
                        expectation.fulfill()
                    }
                }
            case .error(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)
    }

}
