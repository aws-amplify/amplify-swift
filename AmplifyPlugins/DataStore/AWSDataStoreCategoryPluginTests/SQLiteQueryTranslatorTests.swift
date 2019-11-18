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

class SQLiteQueryTranslatorTests: XCTestCase {

    private let models: [Model.Type] = [Post.self, Comment.self]

    let queryTranslator: SQLiteQueryTranslator = SQLiteQueryTranslator()

    override func setUp() {
        models.forEach(registerModel(type:))
    }

    // MARK: - Create Table

    /// it should generate a `create table` statement for a simple model (i.e. no foreign keys)
    func testCreateTableFromSimpleModel() {
        let query = queryTranslator.translateToCreateTable(from: Post.self)
        let expectedStatement = """
        create table if not exists Post (
          "id" text primary key not null,
          "content" text not null,
          "createdAt" text not null,
          "draft" integer not null,
          "rating" real,
          "title" text not null,
          "updatedAt" text
        );
        """
        XCTAssertEqual(query.string, expectedStatement)
    }

    /// it should generate a `create table` statement for a model with foreign keys
    func testCreateTableFromModelWithForeignKey() {
        let query = queryTranslator.translateToCreateTable(from: Comment.self)
        let expectedStatement = """
        create table if not exists Comment (
          "id" text primary key not null,
          "content" text not null,
          "createdAt" text not null,
          "postId" text not null,
          foreign key("postId") references Post("id")
        );
        """
        XCTAssertEqual(query.string, expectedStatement)
    }

    // MARK: - Insert Statements

    /// it should create an `insert into` statement from a model
    func testCreateInsertStatementFromModel() {
        let post = Post(title: "title", content: "content")
        let query = queryTranslator.translateToInsert(from: post)
        let expectedStatement = """
        insert into Post ("id", "content", "createdAt", "draft", "rating", "title", "updatedAt")
        values (?, ?, ?, ?, ?, ?, ?)
        """
        XCTAssertEqual(query.string, expectedStatement)
        XCTAssertEqual(query.arguments[1] as? String, "content")
        XCTAssertEqual(query.arguments[5] as? String, "title")
    }

    /// it should create an `insert into` statement from a model with foreign key
    func testCreateInsertStatementFromModelWithForeignKey() {
        let post = Post(title: "title", content: "content")
        let comment = Comment(content: "comment", post: post)
        let query = queryTranslator.translateToInsert(from: comment)
        let expectedStatement = """
        insert into Comment ("id", "content", "createdAt", "postId")
        values (?, ?, ?, ?)
        """
        XCTAssertEqual(query.string, expectedStatement)
        XCTAssertEqual(query.arguments[1] as? String, "comment")
        XCTAssertEqual(query.arguments[3] as? String, post.id)
    }

    // MARK: - Select Statements

    /// it should create a simple `select from` statement from a model
    func testCreateSimpleSelectStatementFromModel() {
        let query = queryTranslator.translateToQuery(from: Comment.self)
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."content" as "content", "root"."createdAt" as "createdAt",
          "root"."postId" as "postId", "post"."id" as "post.id", "post"."content" as "post.content",
          "post"."createdAt" as "post.createdAt", "post"."draft" as "post.draft", "post"."rating" as "post.rating",
          "post"."title" as "post.title", "post"."updatedAt" as "post.updatedAt"
        from Comment as root
        inner join Post as post
          on "post"."id" = "root"."postId"
        """
        XCTAssertEqual(query.string, expectedStatement)
    }

    // MARK: - Query Predicates

    /// it should translate a single query predicate to a SQL "and" condition
    func testTranslateSingleQueryPredicate() {
        let post = Post.keys

        let predicate = post.id != nil
        let query = queryTranslator.translateQueryPredicate(from: Post.self, predicate: predicate)

        XCTAssertEqual("""
          and "id" is not null
        """, query.string)
        XCTAssert(query.arguments.isEmpty)
    }

    /// it should translate every `QueryPredicateOperation` to valid SQL conditions
    func testTranslateQueryPredicateOperations() {

        func assertPredicate(_ predicate: QueryPredicate,
                             matches sql: String,
                             bindings: [Binding?]? = nil) {
            let query = queryTranslator.translateQueryPredicate(from: Post.self,
                                                                predicate: predicate)
            XCTAssertEqual(query.string, "  and \(sql)")
            if let bindings = bindings {
                XCTAssertEqual(bindings.count, query.arguments.count)
                bindings.enumerated().forEach {
                    if let one = $0.element, let other = query.arguments[$0.offset] {
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

    /// it should translate a complex predicate to a series of SQL conditions
    func testTranslateComplexGroupedQueryPredicate() {
        let post = Post.keys

        let predicate = post.id != nil
            && post.draft == true
            && post.rating > 0
            && post.rating.between(start: 2, end: 4)
            && post.updatedAt == nil
            && (post.content ~= "gelato" || post.title.beginsWith("ice cream"))

        let query = queryTranslator.translateQueryPredicate(from: Post.self, predicate: predicate)

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
        """, query.string)

        XCTAssertEqual(query.arguments[0] as? Int, 1)
        XCTAssertEqual(query.arguments[1] as? Int, 0)
        XCTAssertEqual(query.arguments[2] as? Int, 2)
        XCTAssertEqual(query.arguments[3] as? Int, 4)
        XCTAssertEqual(query.arguments[4] as? String, "%gelato%")
        XCTAssertEqual(query.arguments[5] as? String, "ice cream%")
    }

}
