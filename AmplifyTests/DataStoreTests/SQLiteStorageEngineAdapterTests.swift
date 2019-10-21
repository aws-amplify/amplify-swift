//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SQLite
import XCTest

@testable import Amplify

class SQLiteStorageEngineAdapterTests: XCTestCase {

    var storageAdapter: SQLiteStorageEngineAdapter!

    override func setUp() {
        super.setUp()

        let connection = try? Connection(.inMemory)
        XCTAssertNotNil(connection)
        storageAdapter = SQLiteStorageEngineAdapter(connection: connection!)
        XCTAssertNotNil(storageAdapter)
    }

    // MARK: - Create Statements

    /// it should generate a `create table` statement for a simple model (i.e. no foreign keys)
    func testCreateTableFromSimpleModel() {
        let statement = storageAdapter.getCreateTableStatement(for: Post.self)
        let expectedStatement = """
        create table if not exists Post (
          "id" text primary key not null,
          "title" text not null,
          "content" text not null,
          "createdAt" text not null,
          "updatedAt" text,
          "draft" integer not null
        );
        """
        XCTAssertEqual(statement, expectedStatement)
    }

    /// it should generate a `create table` statement for a model with foreign keys
    func testCreateTableFromModelWithForeignKey() {
        let statement = storageAdapter.getCreateTableStatement(for: Comment.self)
        let expectedStatement = """
        create table if not exists Comment (
          "id" text primary key not null,
          "content" text not null,
          "createdAt" text not null,
          "postId" text not null,
          foreign key("postId") references Post("id")
        );
        """
        XCTAssertEqual(statement, expectedStatement)
    }

    // MARK: - Insert Statements

    /// it should create an `insert into` statement from a model with foreign key
    func testCreateInsertStatementFromModel() {
        let statement = storageAdapter.getInsertStatement(for: Comment.self)
        let expectedStatement = """
        insert into Comment ("id", "content", "createdAt", "postId")
        values (?, ?, ?, ?)
        """
        XCTAssertEqual(statement, expectedStatement)
    }

    // MARK: - Select Statements

    /// it should create a simple `select from` statement from a model
    func testCreateSimpleSelectStatementFromModel() {
        let statement = storageAdapter.getSelectStatement(for: Comment.self)
        let expectedStatement = #"select "id", "content", "createdAt", "postId" from Comment"#
        XCTAssertEqual(statement, expectedStatement)
    }

    // MARK: - Utilities

    func testModelDependencySortOrder() {
        let models: [PersistentModel.Type] = [Comment.self, Post.self]
        let sorted = models.sortByDependencyOrder()

        XCTAssert(models.count == sorted.count)
        XCTAssert(models[0].name == sorted[1].name)
        XCTAssert(models[1].name == sorted[0].name)
    }

    // MARK: - Operations

    /// it should create a table, insert a row and select it
    func testInsertPost() {
        do {
            try storageAdapter.setUp(models: [Post.self])
        } catch {
            XCTFail(String(describing: error))
            return
        }

        let expectation = self.expectation(description: "it should save and select a Post from the database")

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

}
