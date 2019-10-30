//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SQLite
import XCTest

@testable import Amplify
@testable import AWSDataStoreCategoryPlugin

class SQLiteStorageEngineAdapterTests: XCTestCase {

    private let models: [Model.Type] = [Post.self, Comment.self]

    var storageAdapter: SQLiteStorageEngineAdapter!

    override func setUp() {
        super.setUp()

        let connection = try? Connection(.inMemory)
        XCTAssertNotNil(connection)
        storageAdapter = SQLiteStorageEngineAdapter(connection: connection!)
        XCTAssertNotNil(storageAdapter)

        // Register the models for fast lookup
        models.forEach(registerModel(type:))
    }

    // MARK: - Create Statements

    /// it should generate a `create table` statement for a simple model (i.e. no foreign keys)
    func testCreateTableFromSimpleModel() {
        let statement = storageAdapter.getCreateTableStatement(for: Post.self)
        let expectedStatement = """
        create table if not exists Post (
          "id" text primary key not null,
          "content" text not null,
          "createdAt" text not null,
          "draft" integer not null,
          "title" text not null,
          "updatedAt" text
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

    /// it should create an `insert into` statement from a model
    func testCreateInsertStatementFromModel() {
        let statement = storageAdapter.getInsertStatement(for: Post.self)
        let expectedStatement = """
        insert into Post ("id", "content", "createdAt", "draft", "title", "updatedAt")
        values (?, ?, ?, ?, ?, ?)
        """
        XCTAssertEqual(statement, expectedStatement)
    }

    /// it should create an `insert into` statement from a model with foreign key
    func testCreateInsertStatementFromModelWithForeignKey() {
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
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."content" as "content", "root"."createdAt" as "createdAt",
          "root"."postId" as "postId", "post"."id" as "post.id", "post"."content" as "post.content",
          "post"."createdAt" as "post.createdAt", "post"."draft" as "post.draft", "post"."title" as "post.title",
          "post"."updatedAt" as "post.updatedAt"
        from Comment as root
        inner join Post as post
          on "post"."id" = "root"."postId"
        """
        XCTAssertEqual(statement, expectedStatement)
    }

    // MARK: - Utilities

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
        do {
            try storageAdapter.setUp(models: models)
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
