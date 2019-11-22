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

class SQLStatementTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)
    }

    // MARK: - Create Table

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Post`
    ///   - the model has no foreign keys
    /// - Then:
    ///   - check if the generated SQL statement is valid
    func testCreateTableFromSimpleModel() {
        let statement = CreateTableStatement(modelType: Post.self)
        let expectedStatement = """
        create table if not exists Post (
          "id" text primary key not null,
          "_version" integer,
          "content" text not null,
          "createdAt" text not null,
          "draft" integer not null,
          "rating" real,
          "title" text not null,
          "updatedAt" text
        );
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Comment`
    ///   - the model has a foreign key
    /// - Then:
    ///   - check if the generated SQL statement is valid:
    ///     - contains a `foreign key` referencing `Post`
    func testCreateTableFromModelWithForeignKey() {
        let statement = CreateTableStatement(modelType: Comment.self)
        let expectedStatement = """
        create table if not exists Comment (
          "id" text primary key not null,
          "content" text not null,
          "createdAt" text not null,
          "postId" text not null,
          foreign key("postId") references Post("id")
            on delete cascade
        );
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }

    // MARK: - Insert Statements

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model is of type `Post`
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if the variables match the expected values
    func testInsertStatementFromModel() {
        let post = Post(title: "title", content: "content")
        let statement = InsertStatement(model: post)

        let expectedStatement = """
        insert into Post ("id", "_version", "content", "createdAt", "draft", "rating", "title", "updatedAt")
        values (?, ?, ?, ?, ?, ?, ?, ?)
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[2] as? String, "content")
        XCTAssertEqual(variables[6] as? String, "title")
    }

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model is of type `Comment`
    ///   - it has a reference to another `Post`
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if the variables match the expected values
    ///   - check if the `postId` matches `post.id`
    func testInsertStatementFromModelWithForeignKey() {
        let post = Post(title: "title", content: "content")
        let comment = Comment(content: "comment", post: post)
        let statement = InsertStatement(model: comment)

        let expectedStatement = """
        insert into Comment ("id", "content", "createdAt", "postId")
        values (?, ?, ?, ?)
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[1] as? String, "comment")
        XCTAssertEqual(variables[3] as? String, post.id)
    }

    // MARK: - Update Statements

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model is of type `Post`
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if the variables match the expected values
    func testUpdateStatementFromModel() {
        let post = Post(title: "title", content: "content")
        let statement = UpdateStatement(model: post)

        let expectedStatement = """
        update Post
        set
          "_version" = ?,
          "content" = ?,
          "createdAt" = ?,
          "draft" = ?,
          "rating" = ?,
          "title" = ?,
          "updatedAt" = ?
        where "id" = ?
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[1] as? String, "content")
        XCTAssertEqual(variables[5] as? String, "title")
        XCTAssertEqual(variables[7] as? String, post.id)
    }

    // MARK: - Delete Statements

    /// - Given: a `Model` type and an `id`
    /// - When:
    ///   - the model is of type `Post`
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if the variables match the expected values
    func testDeleteStatementFromModel() {
        let id = UUID().uuidString
        let statement = DeleteStatement(modelType: Post.self, withId: id)

        let expectedStatement = """
        delete from Post
        where 1 = 1
            and "id" = ?
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? String, id)
    }

    // MARK: - Select Statements

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Post`
    /// - Then:
    ///   - check if the generated SQL statement is valid
    func testSelectStatementFromModel() {
        let statement = SelectStatement(from: Post.self)
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."_version" as "_version", "root"."content" as "content",
          "root"."createdAt" as "createdAt", "root"."draft" as "draft", "root"."rating" as "rating",
          "root"."title" as "title", "root"."updatedAt" as "updatedAt"
        from Post as root
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Post`
    ///   - a predicate with a few conditions
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - `where` clause is added to the select query
    func testSelectStatementFromModelWithPredicate() {
        let post = Post.keys
        let predicate = post.draft == false && post.rating > 3
        let statement = SelectStatement(from: Post.self, predicate: predicate)
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."_version" as "_version", "root"."content" as "content",
          "root"."createdAt" as "createdAt", "root"."draft" as "draft", "root"."rating" as "rating",
          "root"."title" as "title", "root"."updatedAt" as "updatedAt"
        from Post as root
        where 1 = 1
          and "draft" = ?
          and "rating" > ?
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? Int, 0)
        XCTAssertEqual(variables[1] as? Int, 3)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Comment`
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if an inner join is added referencing `Post`
    func testSelectStatementFromModelWithJoin() {
        let statement = SelectStatement(from: Comment.self)
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."content" as "content", "root"."createdAt" as "createdAt",
          "root"."postId" as "postId", "post"."id" as "post.id", "post"."_version" as "post._version",
          "post"."content" as "post.content", "post"."createdAt" as "post.createdAt", "post"."draft" as "post.draft",
          "post"."rating" as "post.rating", "post"."title" as "post.title", "post"."updatedAt" as "post.updatedAt"
        from Comment as root
        inner join Post as post
          on "post"."id" = "root"."postId"
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }

    // MARK: - Query Predicates

    /// - Given: a simple predicate
    /// - When:
    ///   - the field is `id`
    ///   - the operator is `ne`
    /// - Then:
    ///   - check if the generated SQL statement is valid
    func testTranslateSingleQueryPredicate() {
        let post = Post.keys

        let predicate = post.id != nil
        let statement = ConditionStatement(modelType: Post.self, predicate: predicate)

        XCTAssertEqual("""
          and "id" is not null
        """, statement.stringValue)
        XCTAssert(statement.variables.isEmpty)
    }

    /// - Given: a set of all available predicate operations
    /// - When:
    ///   - each operation is defined
    /// - Then:
    ///   - it matches the SQL condition
    func testTranslateQueryPredicateOperations() {

        func assertPredicate(_ predicate: QueryPredicate,
                             matches sql: String,
                             bindings: [Binding?]? = nil) {
            let statement = ConditionStatement(modelType: Post.self, predicate: predicate)
            XCTAssertEqual(statement.stringValue, "  and \(sql)")
            if let bindings = bindings {
                XCTAssertEqual(bindings.count, statement.variables.count)
                bindings.enumerated().forEach {
                    if let one = $0.element, let other = statement.variables[$0.offset] {
                        // TODO find better way to test `Binding` equality
                        XCTAssertEqual(String(describing: one), String(describing: other))
                    }
                }
            }
        }

        let post = Post.keys
        assertPredicate(post.id == nil, matches: "\"id\" is null")
        assertPredicate(post.id != nil, matches: "\"id\" is not null")
        assertPredicate(post.draft == true, matches: "\"draft\" = ?", bindings: [1])
        assertPredicate(post.draft != false, matches: "\"draft\" <> ?", bindings: [0])
        assertPredicate(post.rating > 0, matches: "\"rating\" > ?", bindings: [0])
        assertPredicate(post.rating >= 1, matches: "\"rating\" >= ?", bindings: [1])
        assertPredicate(post.rating < 2, matches: "\"rating\" < ?", bindings: [2])
        assertPredicate(post.rating <= 3, matches: "\"rating\" <= ?", bindings: [3])
        assertPredicate(post.rating.between(start: 3, end: 5),
                        matches: "\"rating\" between ? and ?",
                        bindings: [3, 5])
        assertPredicate(post.title.beginsWith("gelato"),
                        matches: "\"title\" like ?",
                        bindings: ["gelato%"])
        assertPredicate(post.title ~= "gelato",
                        matches: "\"title\" like ?",
                        bindings: ["%gelato%"])
    }

    /// - Given: a grouped predicate
    /// - When:
    ///   - the predicate contains a set of different operations
    /// - Then:
    ///   - it generates a valid series of SQL conditions
    func testTranslateComplexGroupedQueryPredicate() {
        let post = Post.keys

        let predicate = post.id != nil
            && post.draft == true
            && post.rating > 0
            && post.rating.between(start: 2, end: 4)
            && post.updatedAt == nil
            && (post.content ~= "gelato" || post.title.beginsWith("ice cream"))

        let statement = ConditionStatement(modelType: Post.self, predicate: predicate)

        XCTAssertEqual("""
          and "id" is not null
          and "draft" = ?
          and "rating" > ?
          and "rating" between ? and ?
          and "updatedAt" is null
          and (
            "content" like ?
            or "title" like ?
          )
        """, statement.stringValue)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? Int, 1)
        XCTAssertEqual(variables[1] as? Int, 0)
        XCTAssertEqual(variables[2] as? Int, 2)
        XCTAssertEqual(variables[3] as? Int, 4)
        XCTAssertEqual(variables[4] as? String, "%gelato%")
        XCTAssertEqual(variables[5] as? String, "ice cream%")
    }

}
