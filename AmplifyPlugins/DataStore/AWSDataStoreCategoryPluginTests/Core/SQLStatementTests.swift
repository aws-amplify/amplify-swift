//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

// swiftlint:disable type_body_length
// swiftlint:disable file_length
// TODO: Refactor this into separate test suites
class SQLStatementTests: XCTestCase {

    override func setUp() {
        // one-to-many/many-to-one association
        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)

        // one-to-one association
        ModelRegistry.register(modelType: UserAccount.self)
        ModelRegistry.register(modelType: UserProfile.self)

        // many-to-many association
        ModelRegistry.register(modelType: Author.self)
        ModelRegistry.register(modelType: Book.self)
        ModelRegistry.register(modelType: BookAuthor.self)

        // Reserved word
        ModelRegistry.register(modelType: Transaction.self)

        // Secondary Indexes
        ModelRegistry.register(modelType: CustomerSecondaryIndexV2.self)
        ModelRegistry.register(modelType: CustomerMultipleSecondaryIndexV2.self)

        // Custom PK
        ModelRegistry.register(modelType: ModelImplicitDefaultPk.self)
        ModelRegistry.register(modelType: ModelExplicitDefaultPk.self)
        ModelRegistry.register(modelType: ModelExplicitCustomPk.self)
        ModelRegistry.register(modelType: ModelCompositePk.self)
    }

    // MARK: - Create Table

    func testCreateTableWithReservedWord() {
        let statement = CreateTableStatement(modelSchema: Transaction.schema)
        let expectedStatement = """
        create table if not exists "Transaction" (
          "id" text primary key not null
        );
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Post`
    ///   - the model has no foreign keys
    /// - Then:
    ///   - check if the generated SQL statement is valid
    func testCreateTableFromSimpleModel() {
        let statement = CreateTableStatement(modelSchema: Post.schema)
        let expectedStatement = """
        create table if not exists "Post" (
          "id" text primary key not null,
          "content" text not null,
          "createdAt" text not null,
          "draft" integer,
          "rating" real,
          "status" text,
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
        let statement = CreateTableStatement(modelSchema: Comment.schema)
        let expectedStatement = """
        create table if not exists "Comment" (
          "id" text primary key not null,
          "content" text not null,
          "createdAt" text not null,
          "commentPostId" text not null,
          foreign key("commentPostId") references "Post"("id")
            on delete cascade
        );
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `UserAccount`
    ///   - the model has an `unique` foreign key
    /// - Then:
    ///   - check if the generated SQL statement is valid:
    ///     - contains a `foreign key` referencing `UserProfile`
    ///     - the foreign key column is `unique`
    func testCreateTableFromModelWithOneToOneForeignKey() {
        let statement = CreateTableStatement(modelSchema: UserProfile.schema)
        let expectedStatement = """
        create table if not exists "UserProfile" (
          "id" text primary key not null,
          "accountId" text not null unique,
          foreign key("accountId") references "UserAccount"("id")
            on delete cascade
        );
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `BookAuthor`
    ///   - the model represents an association of `many-to-many` between `Book` and `Author`
    /// - Then:
    ///   - check if the generated SQL statement is valid:
    ///     - contains a `foreign key` referencing `Author`
    ///     - contains a `foreign key` referencing `Book`
    func testCreateTableFromManyToManyAssociationModel() {
        let statement = CreateTableStatement(modelSchema: BookAuthor.schema)
        let expectedStatement = """
        create table if not exists "BookAuthor" (
          "id" text primary key not null,
          "authorId" text not null,
          "bookId" text not null,
          foreign key("authorId") references "Author"("id")
            on delete cascade
          foreign key("bookId") references "Book"("id")
            on delete cascade
        );
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }


    func testCreateTableFromModelWithImplicitDefaultPk() {
        let statement = CreateTableStatement(modelSchema: ModelImplicitDefaultPk.schema)
        let expectedStatement = """
        create table if not exists "ModelImplicitDefaultPk" (
          "id" text primary key not null,
          "createdAt" text,
          "name" text,
          "updatedAt" text
        );
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }

    func testCreateTableFromModelWithExplicitDefaultPk() {
        let statement = CreateTableStatement(modelSchema: ModelExplicitDefaultPk.schema)
        let expectedStatement = """
        create table if not exists "ModelExplicitDefaultPk" (
          "id" text primary key not null,
          "createdAt" text,
          "name" text,
          "updatedAt" text
        );
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }

    func testCreateTableFromModelWithCustomPk() {
        let statement = CreateTableStatement(modelSchema: ModelExplicitCustomPk.schema)
        let expectedStatement = """
        create table if not exists "ModelExplicitCustomPk" (
          "userId" text primary key not null,
          "createdAt" text,
          "name" text,
          "updatedAt" text
        );
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }

    func testCreateTableFromModelWithCompositePk() {
        let statement = CreateTableStatement(modelSchema: ModelCompositePk.schema)
        let expectedStatement = """
        create table if not exists "ModelCompositePk" (
          "@@primaryKey" text primary key not null,
          "id" text not null,
          "dob" text not null,
          "createdAt" text,
          "name" text,
          "updatedAt" text
        );
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }

    // MARK: - Create Index

    /// - Given: a `Model` instance
    /// - When:
    ///     - the model is of type `CustomerSecondaryIndexV2`
    /// - Then:
    ///   - check if the generated SQL statement is valid
    func testCreateIndexStatementFromModelWithSingleIndex() {
        let statement = CustomerSecondaryIndexV2.schema.createIndexStatements()
        let expectedStatement = """
        create index if not exists "byRepresentative" on "CustomerSecondaryIndexV2" ("accountRepresentativeID");
        """
        XCTAssertEqual(statement, expectedStatement)
    }

    /// - Given: a `Model` instance
    /// - When:
    ///     - the model is of type `CustomerMultipleSecondaryIndexV2`
    /// - Then:
    ///   - check if the generated SQL statement is valid
    func testCreateIndexStatementFromModelWithMultipleIndexes() {
        let statement = CustomerMultipleSecondaryIndexV2.schema.createIndexStatements()
        let expectedStatement = """
        create index if not exists "byNameAndPhoneNumber" on "CustomerMultipleSecondaryIndexV2" ("name", "phoneNumber");\
        create index if not exists "byAgeAndPhoneNumber" on "CustomerMultipleSecondaryIndexV2" ("age", "phoneNumber");\
        create index if not exists "byRepresentative" on "CustomerMultipleSecondaryIndexV2" ("accountRepresentativeID");
        """
        XCTAssertEqual(statement, expectedStatement)
    }

    // MARK: - Insert Statements

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model is of type `Post`
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if the variables match the expected values
    func testInsertStatementFromModel() {
        let post = Post(title: "title",
                        content: "content",
                        createdAt: .now(),
                        status: .draft)
        let statement = InsertStatement(model: post, modelSchema: post.schema)

        let expectedStatement = """
        insert into "Post" ("id", "content", "createdAt", "draft", "rating", "status", "title", "updatedAt")
        values (?, ?, ?, ?, ?, ?, ?, ?)
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[1] as? String, "content")
        XCTAssertEqual(variables[5] as? String, "DRAFT")
        XCTAssertEqual(variables[6] as? String, "title")
    }

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model has a composite pk
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if the variables match the expected values
    func testInsertStatementFromModelWithCompositePK() {

        let modelId = "the-id"
        let dob = Temporal.DateTime.now()
        let model = ModelCompositePk(id: modelId,
                                     dob: dob,
                                     name: "the-name")
        let statement = InsertStatement(model: model, modelSchema: model.schema)

        let expectedStatement = """
        insert into "ModelCompositePk" ("@@primaryKey", "id", "dob", "createdAt", "name", "updatedAt")
        values (?, ?, ?, ?, ?, ?)
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? String, "\(modelId)#\(dob.iso8601String)")
        XCTAssertEqual(variables[1] as? String, modelId)
        XCTAssertEqual(variables[2] as? String, dob.iso8601String)
        XCTAssertEqual(variables[4] as? String, "the-name")
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
        let post = Post(title: "title", content: "content", createdAt: .now())
        let comment = Comment(content: "comment", createdAt: .now(), post: post)
        let statement = InsertStatement(model: comment, modelSchema: comment.schema)

        let expectedStatement = """
        insert into "Comment" ("id", "content", "createdAt", "commentPostId")
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
        let post = Post(title: "title", content: "content", createdAt: .now())
        let statement = UpdateStatement(model: post, modelSchema: post.schema)

        let expectedStatement = """
        update Post
        set
          "content" = ?,
          "createdAt" = ?,
          "draft" = ?,
          "rating" = ?,
          "status" = ?,
          "title" = ?,
          "updatedAt" = ?
        where "id" = ?
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? String, "content")
        XCTAssertEqual(variables[5] as? String, "title")
        XCTAssertEqual(variables[7] as? String, post.id)
    }

    /// - Given: a `Model` instance, with condition
    /// - When:
    ///   - the model is of type `Post`
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if the variables match the expected values
    func testUpdateStatementFromModelWithCondition() {
        let post = Post(title: "title", content: "content", createdAt: .now())
        let condition = Post.keys.content == "content2"
        let statement = UpdateStatement(model: post, modelSchema: post.schema, condition: condition)

        let expectedStatement = """
        update Post
        set
          "content" = ?,
          "createdAt" = ?,
          "draft" = ?,
          "rating" = ?,
          "status" = ?,
          "title" = ?,
          "updatedAt" = ?
        where "id" = ?
          and "content" = ?
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? String, "content")
        XCTAssertEqual(variables[5] as? String, "title")
        XCTAssertEqual(variables[7] as? String, post.id)
    }

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model has a custom primary key defined as a model schema attribute
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if the variables match the expected values
    func testUpdateStatementFromModelWithDefinedCustomPK() {
        let modelId = "the-id"
        let dob = Temporal.DateTime.now()
        let model = ModelCustomPkDefined(id: modelId,
                                         dob: dob,
                                         name: "the-name")
        let statement = UpdateStatement(model: model, modelSchema: model.schema)
        let expectedStatement = """
        update ModelCustomPkDefined
        set
          "id" = ?,
          "dob" = ?,
          "createdAt" = ?,
          "name" = ?,
          "updatedAt" = ?
        where "@@primaryKey" = ?
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? String, modelId)
        XCTAssertEqual(variables[1] as? String, dob.iso8601String)
        XCTAssertEqual(variables[3] as? String, "the-name")
        XCTAssertEqual(variables[5] as? String, model.identifier(schema: model.schema).stringValue)
    }

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model has a custom primary key defined with indexes (backward compatibility)
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if the variables match the expected values
    func testUpdateStatementFromModelWithCustomPKBasedOnIndexes() {
        let modelId = "the-id"
        let dob = Temporal.DateTime.now()
        let model = ModelCompositePk(id: modelId,
                                     dob: dob,
                                     name: "the-name")
        let statement = UpdateStatement(model: model, modelSchema: model.schema)
        let expectedStatement = """
        update ModelCompositePk
        set
          "id" = ?,
          "dob" = ?,
          "createdAt" = ?,
          "name" = ?,
          "updatedAt" = ?
        where "@@primaryKey" = ?
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? String, modelId)
        XCTAssertEqual(variables[1] as? String, dob.iso8601String)
        XCTAssertEqual(variables[3] as? String, "the-name")
        XCTAssertEqual(variables[5] as? String, model.identifier(schema: model.schema).stringValue)
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
        let statement = DeleteStatement(Post.self,
                                        modelSchema: Post.schema,
                                        withId: id)

        let expectedStatement = """
        delete from "Post" as root
        where 1 = 1
          and "root"."id" = ?
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? String, id)
    }

    /// - Given: a `Model` type and an `id`
    /// - When:
    ///   - the model is of type `Post` with condition
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if the variables match the expected values
    func testDeleteStatementFromModelWithCondition() {
        let id = UUID().uuidString
        let statement = DeleteStatement(Post.self,
                                        modelSchema: Post.schema,
                                        withId: id,
                                        predicate: Post.keys.content == "content")

        let expectedStatement = """
        delete from "Post" as root
        where 1 = 1
          and (
            "root"."id" = ?
            and "root"."content" = ?
          )
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? String, id)
        XCTAssertEqual(variables[1] as? String, "content")
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `ModelExplicitCustomPk` and has a custom PK
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if the variables match the expected values
    func testDeleteStatementFromModelWithCustomPK() {
        let identifier = ModelExplicitCustomPk.Identifier.identifier(userId: "userId")
        let statement = DeleteStatement(modelSchema: ModelExplicitCustomPk.schema,
                                        withIdentifier: identifier)

        let expectedStatement = """
        delete from "ModelExplicitCustomPk" as root
        where 1 = 1
          and "root"."userId" = ?
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? String, identifier.stringValue)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `ModelCompositePk` and has a composite PK
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if the variables match the expected values
    func testDeleteStatementFromModelWithCompositePK() {
        let identifier = ModelCompositePk.Identifier.identifier(id: "id",
                                                        dob: Temporal.DateTime.now())
        let statement = DeleteStatement(modelSchema: ModelCompositePk.schema,
                                        withIdentifier: identifier)

        let expectedStatement = """
        delete from "ModelCompositePk" as root
        where 1 = 1
          and "root"."@@primaryKey" = ?
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? String, identifier.stringValue)
    }

    // MARK: - Select Statements

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Post`
    /// - Then:
    ///   - check if the generated SQL statement is valid
    func testSelectStatementFromModel() {
        let statement = SelectStatement(from: Post.schema)
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."content" as "content", "root"."createdAt" as "createdAt",
          "root"."draft" as "draft", "root"."rating" as "rating", "root"."status" as "status",
          "root"."title" as "title", "root"."updatedAt" as "updatedAt"
        from "Post" as "root"
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `ModelCompositePk` and has a composite PK
    /// - Then:
    ///   - check if the generated SQL statement is valid
    func testSelectStatementFromModelWithCompositePK() {
        let statement = SelectStatement(from: ModelCompositePk.schema)
        let expectedStatement = """
        select
          "root"."@@primaryKey" as "@@primaryKey", "root"."id" as "id", "root"."dob" as "dob",
          "root"."createdAt" as "createdAt", "root"."name" as "name", "root"."updatedAt" as "updatedAt"
        from "ModelCompositePk" as "root"
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
        let statement = SelectStatement(from: Post.schema, predicate: predicate)
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."content" as "content", "root"."createdAt" as "createdAt",
          "root"."draft" as "draft", "root"."rating" as "rating", "root"."status" as "status",
          "root"."title" as "title", "root"."updatedAt" as "updatedAt"
        from "Post" as "root"
        where 1 = 1
          and (
            "root"."draft" = ?
            and "root"."rating" > ?
          )
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? Int, 0)
        XCTAssertEqual(variables[1] as? Int, 3)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Post`
    /// - Then:
    ///   - check if the generated SQL statement is valid
    func testSelectStatementWithPredicateFromModelWithCompositePK() {
        let keys = ModelCompositePk.keys
        let modelId = "an-id"
        let dob = "2022-02-22"
        let statement = SelectStatement(from: ModelCompositePk.schema,
                                        predicate: keys.id == modelId && keys.dob == dob)
        let expectedStatement = """
        select
          "root"."@@primaryKey" as "@@primaryKey", "root"."id" as "id", "root"."dob" as "dob",
          "root"."createdAt" as "createdAt", "root"."name" as "name", "root"."updatedAt" as "updatedAt"
        from "ModelCompositePk" as "root"
        where 1 = 1
          and (
            "root"."id" = ?
            and "root"."dob" = ?
          )
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
        XCTAssertEqual(statement.variables.count, 2)
        XCTAssertEqual(statement.variables[0] as? String, modelId)
        XCTAssertEqual(statement.variables[1] as? String, dob)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Comment`
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if an inner join is added referencing `Post`
    ///   - check if
    func testSelectStatementFromQueryPredicateWithConnectedField() {
        let comment = Comment.keys

        let predicate = comment.id == "commentId"
            && comment.content == "content"
            && comment.createdAt == nil
            && comment.post == "PostID"

        let statement = SelectStatement(from: Comment.schema, predicate: predicate)
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."content" as "content", "root"."createdAt" as "createdAt",
          "root"."commentPostId" as "commentPostId", "post"."id" as "post.id", "post"."content" as "post.content",
          "post"."createdAt" as "post.createdAt", "post"."draft" as "post.draft", "post"."rating" as "post.rating",
          "post"."status" as "post.status", "post"."title" as "post.title", "post"."updatedAt" as "post.updatedAt"
        from "Comment" as "root"
        inner join "Post" as "post"
          on "post"."id" = "root"."commentPostId"
        where 1 = 1
          and (
            "root"."id" = ?
            and "root"."content" = ?
            and "root"."createdAt" is null
            and "root"."commentPostId" = ?
          )
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? String, "commentId")
        XCTAssertEqual(variables[1] as? String, "content")
        XCTAssertEqual(variables[2] as? String, "PostID")
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Comment`
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if an inner join is added referencing `Post`
    func testSelectStatementFromModelWithJoin() {
        let statement = SelectStatement(from: Comment.schema)
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."content" as "content", "root"."createdAt" as "createdAt",
          "root"."commentPostId" as "commentPostId", "post"."id" as "post.id", "post"."content" as "post.content",
          "post"."createdAt" as "post.createdAt", "post"."draft" as "post.draft", "post"."rating" as "post.rating",
          "post"."status" as "post.status", "post"."title" as "post.title", "post"."updatedAt" as "post.updatedAt"
        from "Comment" as "root"
        inner join "Post" as "post"
          on "post"."id" = "root"."commentPostId"
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }

    // MARK: - Select Statements paginated

    /// - Given: a `Model` type and a `QueryPaginationInput`
    /// - When:
    ///   - the model is of type `Post`
    ///   - the pagination input has `page` 2 and `limit` 20
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if the statement contains the correct `limit` and `offset`
    func testSelectStatementWithPaginationInfo() {
        let statement = SelectStatement(from: Post.schema, predicate: nil, paginationInput: .page(2, limit: 20))
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."content" as "content", "root"."createdAt" as "createdAt",
          "root"."draft" as "draft", "root"."rating" as "rating", "root"."status" as "status",
          "root"."title" as "title", "root"."updatedAt" as "updatedAt"
        from "Post" as "root"
        limit 20 offset 40
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }

    // MARK: - Select Statements Sort

    /// - Given: a `Model` type and a `QuerySortBy`
    /// - When:
    ///   - the model is of type `Post`
    ///   - the sort should be `id` of ascending order
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if the statement contains the correct `order by` and `ascending`
    func testSelectStatementWithOneSort() {
        let ascSort = QuerySortDescriptor(fieldName: Post.keys.id.stringValue, order: .ascending)
        let statement = SelectStatement(from: Post.schema, sort: [ascSort])
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."content" as "content", "root"."createdAt" as "createdAt",
          "root"."draft" as "draft", "root"."rating" as "rating", "root"."status" as "status",
          "root"."title" as "title", "root"."updatedAt" as "updatedAt"
        from "Post" as "root"
        order by "root"."id" asc
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }

    /// - Given: a `Model` type and two `QuerySortBy`s
    /// - When:
    ///   - the model is of type `Post`
    ///   - the sort should be `id` of descending order and `createdAt` of descending order
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if the statement contains the correct `order by` and `ascending`
    func testSelectStatementWithTwoFieldsSort() {
        let ascSort = QuerySortDescriptor(fieldName: Post.keys.id.stringValue, order: .ascending)
        let dscSort = QuerySortDescriptor(fieldName: Post.keys.createdAt.stringValue, order: .descending)
        let statement = SelectStatement(from: Post.schema,
                                        sort: [ascSort, dscSort])
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."content" as "content", "root"."createdAt" as "createdAt",
          "root"."draft" as "draft", "root"."rating" as "rating", "root"."status" as "status",
          "root"."title" as "title", "root"."updatedAt" as "updatedAt"
        from "Post" as "root"
        order by "root"."id" asc, "root"."createdAt" desc
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }

    /// - Given: a `Model` type, a `QueryPredicate`and  a `QuerySortBy`
    /// - When:
    ///   - the model is of type `Post`
    ///   - the sort should meet predicate condition be `id` of descending order
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if the statement contains the correct `where` statement, `order by` and `ascending`
    func testSelectStatementWithPredicateAndSort() {
        let sort = QuerySortDescriptor(fieldName: Post.keys.id.stringValue, order: .descending)
        let statement = SelectStatement(from: Post.schema,
                                        predicate: Post.keys.rating > 4,
                                        sort: [sort])
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."content" as "content", "root"."createdAt" as "createdAt",
          "root"."draft" as "draft", "root"."rating" as "rating", "root"."status" as "status",
          "root"."title" as "title", "root"."updatedAt" as "updatedAt"
        from "Post" as "root"
        where 1 = 1
          and "root"."rating" > ?
        order by "root"."id" desc
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }

    /// - Given: a `Model` type, a `QuerySortBy`, a `QueryPaginationInput`
    /// - When:
    ///   - the model is of type `Post`
    ///   - the sort should be `id` of descending order and
    ///   - the pagination input has `page` 0 and `limit` 5
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if the statement contains the correct `where` statement, `order by` and `ascending`
    func testSelectStatementWithSortAndPaginationInfo() {
        let sort = QuerySortDescriptor(fieldName: Post.keys.id.stringValue, order: .descending)
        let statement = SelectStatement(from: Post.schema,
                                        sort: [sort],
                                        paginationInput: .page(0, limit: 5))
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."content" as "content", "root"."createdAt" as "createdAt",
          "root"."draft" as "draft", "root"."rating" as "rating", "root"."status" as "status",
          "root"."title" as "title", "root"."updatedAt" as "updatedAt"
        from "Post" as "root"
        order by "root"."id" desc
        limit 5 offset 0
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)
    }

    /// - Given: a `Model` type, a `QueryPredicate`,  a `QuerySortBy` and a `QueryPaginationInput`
    /// - When:
    ///   - the model is of type `Post`
    ///   - the predicate should meet the condtion
    ///   - the sort should  be `id` of descending order
    ///   - the pagination input has `page` 0 and `limit` 5
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - check if the statement contains the correct `where` statement, `order by` and `ascending`
    func testSelectStatementWithPredicateAndSortAndPaginationInfo() {
        let sort = QuerySortDescriptor(fieldName: Post.keys.id.stringValue, order: .descending)
        let statement = SelectStatement(from: Post.schema,
                                        predicate: Post.keys.rating > 4,
                                        sort: [sort],
                                        paginationInput: .page(0, limit: 5))
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."content" as "content", "root"."createdAt" as "createdAt",
          "root"."draft" as "draft", "root"."rating" as "rating", "root"."status" as "status",
          "root"."title" as "title", "root"."updatedAt" as "updatedAt"
        from "Post" as "root"
        where 1 = 1
          and "root"."rating" > ?
        order by "root"."id" desc
        limit 5 offset 0
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
        let statement = ConditionStatement(modelSchema: Post.schema, predicate: predicate)

        XCTAssertEqual("""
          and "id" is not null
        """, statement.stringValue)
        XCTAssert(statement.variables.isEmpty)
    }

    /// - Given: a simple predicate and namespace
    /// - When:
    ///   - the field is `id`
    ///   - the operator is `ne`
    /// - Then:
    ///   - check if the generated SQL statement is valid
    func testTranslateSingleQueryPredicateWithNamespace() {
        let post = Post.keys

        let predicate = post.id != nil
        let statement = ConditionStatement(modelSchema: Post.schema, predicate: predicate, namespace: "root")

        XCTAssertEqual("""
          and "root"."id" is not null
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
            let statement = ConditionStatement(modelSchema: Post.schema, predicate: predicate, namespace: "root")
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
        assertPredicate(post.id == nil, matches: "\"root\".\"id\" is null")
        assertPredicate(post.id != nil, matches: "\"root\".\"id\" is not null")
        assertPredicate(post.draft == true, matches: "\"root\".\"draft\" = ?", bindings: [1])
        assertPredicate(post.draft != false, matches: "\"root\".\"draft\" <> ?", bindings: [0])
        assertPredicate(post.rating > 0, matches: "\"root\".\"rating\" > ?", bindings: [0])
        assertPredicate(post.rating >= 1, matches: "\"root\".\"rating\" >= ?", bindings: [1])
        assertPredicate(post.rating < 2, matches: "\"root\".\"rating\" < ?", bindings: [2])
        assertPredicate(post.rating <= 3, matches: "\"root\".\"rating\" <= ?", bindings: [3])
        assertPredicate(post.rating.between(start: 3, end: 5),
                        matches: "\"root\".\"rating\" between ? and ?",
                        bindings: [3, 5])
        assertPredicate(post.title.beginsWith("gelato"),
                        matches: "\"root\".\"title\" like ?",
                        bindings: ["gelato%"])
        assertPredicate(post.title ~= "gelato",
                        matches: "\"root\".\"title\" like ?",
                        bindings: ["%gelato%"])
    }

    /// - Given: a grouped predicate
    /// - When:
    ///   - the predicate contains a set of different operations
    /// - Then:
    ///   - it generates a valid series of SQL conditions
    func testTranslateComplexGroupedQueryPredicateScenario1() {
        let post = Post.keys

        let predicate = post.id != nil
            && post.draft == true
            && post.rating > 0
            && post.rating.between(start: 2, end: 4)
            && post.status != PostStatus.draft
            && post.updatedAt == nil
            && (post.content ~= "gelato" || post.title.beginsWith("ice cream"))

        let statement = ConditionStatement(modelSchema: Post.schema, predicate: predicate)

        XCTAssertEqual("""
          and (
            "id" is not null
            and "draft" = ?
            and "rating" > ?
            and "rating" between ? and ?
            and "status" <> ?
            and "updatedAt" is null
            and (
              "content" like ?
              or "title" like ?
            )
          )
        """, statement.stringValue)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? Int, 1)
        XCTAssertEqual(variables[1] as? Int, 0)
        XCTAssertEqual(variables[2] as? Int, 2)
        XCTAssertEqual(variables[3] as? Int, 4)
        XCTAssertEqual(variables[4] as? String, PostStatus.draft.rawValue)
        XCTAssertEqual(variables[5] as? String, "%gelato%")
        XCTAssertEqual(variables[6] as? String, "ice cream%")
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Post`
    ///   - a predicate with a few grouped conditions
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - `where` clause is added to the select query
    ///   - `where` clause is correctly generated
    func testTranslateComplexGroupedQueryPredicateScenario2() {
        let post = Post.keys
        let predicate = (post.id == "postID" && post.draft == false) || post.rating > 3
        let statement = SelectStatement(from: Post.schema, predicate: predicate)
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."content" as "content", "root"."createdAt" as "createdAt",
          "root"."draft" as "draft", "root"."rating" as "rating", "root"."status" as "status",
          "root"."title" as "title", "root"."updatedAt" as "updatedAt"
        from "Post" as "root"
        where 1 = 1
          and (
            (
              "root"."id" = ?
              and "root"."draft" = ?
            )
            or "root"."rating" > ?
          )
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? String, "postID")
        XCTAssertEqual(variables[1] as? Int, 0)
        XCTAssertEqual(variables[2] as? Int, 3)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Post`
    ///   - a predicate with a few grouped conditions
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - `where` clause is added to the select query
    ///   - `where` clause is correctly generated
    func testTranslateComplexGroupedQueryPredicateScenario3() {
        let post = Post.keys
        let predicate = (post.id == "postID" || post.draft == false) && post.rating > 3
        let statement = SelectStatement(from: Post.schema, predicate: predicate)
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."content" as "content", "root"."createdAt" as "createdAt",
          "root"."draft" as "draft", "root"."rating" as "rating", "root"."status" as "status",
          "root"."title" as "title", "root"."updatedAt" as "updatedAt"
        from "Post" as "root"
        where 1 = 1
          and (
            (
              "root"."id" = ?
              or "root"."draft" = ?
            )
            and "root"."rating" > ?
          )
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? String, "postID")
        XCTAssertEqual(variables[1] as? Int, 0)
        XCTAssertEqual(variables[2] as? Int, 3)
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Post`
    ///   - a predicate with a few grouped conditions
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - `where` clause is added to the select query
    ///   - `where` clause is correctly generated
    func testTranslateComplexGroupedQueryPredicateScenario4() {
        let post = Post.keys
        let predicate = (post.id == "postID" || post.draft == false) && (post.rating > 3 || post.createdAt == "time")
        let statement = SelectStatement(from: Post.schema, predicate: predicate)
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."content" as "content", "root"."createdAt" as "createdAt",
          "root"."draft" as "draft", "root"."rating" as "rating", "root"."status" as "status",
          "root"."title" as "title", "root"."updatedAt" as "updatedAt"
        from "Post" as "root"
        where 1 = 1
          and (
            (
              "root"."id" = ?
              or "root"."draft" = ?
            )
            and (
              "root"."rating" > ?
              or "root"."createdAt" = ?
            )
          )
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? String, "postID")
        XCTAssertEqual(variables[1] as? Int, 0)
        XCTAssertEqual(variables[2] as? Int, 3)
        XCTAssertEqual(variables[3] as? String, "time")
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Post`
    ///   - a predicate with a few grouped conditions
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - `where` clause is added to the select query
    ///   - `where` clause is correctly generated
    func testTranslateComplexGroupedQueryPredicateScenario5() {
        let post = Post.keys
        let predicate = (post.id == "postID" && post.draft == false) || (post.rating > 3 && post.createdAt == "time")
        let statement = SelectStatement(from: Post.schema, predicate: predicate)
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."content" as "content", "root"."createdAt" as "createdAt",
          "root"."draft" as "draft", "root"."rating" as "rating", "root"."status" as "status",
          "root"."title" as "title", "root"."updatedAt" as "updatedAt"
        from "Post" as "root"
        where 1 = 1
          and (
            (
              "root"."id" = ?
              and "root"."draft" = ?
            )
            or (
              "root"."rating" > ?
              and "root"."createdAt" = ?
            )
          )
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? String, "postID")
        XCTAssertEqual(variables[1] as? Int, 0)
        XCTAssertEqual(variables[2] as? Int, 3)
        XCTAssertEqual(variables[3] as? String, "time")
    }

    /// - Given: a `Model` type
    /// - When:
    ///   - the model is of type `Post`
    ///   - a predicate with a few grouped conditions
    /// - Then:
    ///   - check if the generated SQL statement is valid
    ///   - `where` clause is added to the select query
    ///   - `where` clause is correctly generated
    func testTranslateComplexGroupedQueryPredicateScenario6() {
        let post = Post.keys
        let predicate = (post.id == "postID" || post.draft == false && post.content == "content")
            && (post.rating > 3 && post.createdAt == "time")
        let statement = SelectStatement(from: Post.schema, predicate: predicate)
        let expectedStatement = """
        select
          "root"."id" as "id", "root"."content" as "content", "root"."createdAt" as "createdAt",
          "root"."draft" as "draft", "root"."rating" as "rating", "root"."status" as "status",
          "root"."title" as "title", "root"."updatedAt" as "updatedAt"
        from "Post" as "root"
        where 1 = 1
          and (
            (
              "root"."id" = ?
              or (
                "root"."draft" = ?
                and "root"."content" = ?
              )
            )
            and (
              "root"."rating" > ?
              and "root"."createdAt" = ?
            )
          )
        """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? String, "postID")
        XCTAssertEqual(variables[1] as? Int, 0)
        XCTAssertEqual(variables[2] as? String, "content")
        XCTAssertEqual(variables[3] as? Int, 3)
        XCTAssertEqual(variables[4] as? String, "time")
    }

    /// - Given: a grouped predicate and namespace
    /// - When:
    ///   - the predicate contains a set of different operations
    /// - Then:
    ///   - it generates a valid series of SQL conditions
    func testTranslateComplexGroupedQueryPredicateWithNamespace() {
        let post = Post.keys

        let predicate = post.id != nil
            && post.draft == true
            && post.rating > 0
            && post.rating.between(start: 2, end: 4)
            && post.updatedAt == nil
            && (post.content ~= "gelato" || post.title.beginsWith("ice cream"))

        let statement = ConditionStatement(modelSchema: Post.schema, predicate: predicate, namespace: "root")
        let expectedStatement =
            """
              and (
                "root"."id" is not null
                and "root"."draft" = ?
                and "root"."rating" > ?
                and "root"."rating" between ? and ?
                and "root"."updatedAt" is null
                and (
                  "root"."content" like ?
                  or "root"."title" like ?
                )
              )
            """
        XCTAssertEqual(statement.stringValue, expectedStatement)

        let variables = statement.variables
        XCTAssertEqual(variables[0] as? Int, 1)
        XCTAssertEqual(variables[1] as? Int, 0)
        XCTAssertEqual(variables[2] as? Int, 2)
        XCTAssertEqual(variables[3] as? Int, 4)
        XCTAssertEqual(variables[4] as? String, "%gelato%")
        XCTAssertEqual(variables[5] as? String, "ice cream%")
    }

    func testTranslateQueryPredicateWithNameSpaceWhenFieldNameSpecified() {
        let predicate = field("commentPostId") == "postID"

        let statement = ConditionStatement(modelSchema: Post.schema, predicate: predicate, namespace: "root")
        let variables = statement.variables

        let expectStatement = """
          and "root"."commentPostId" = ?
        """
        let expectedVariable = "postID"

        XCTAssertEqual(statement.stringValue, expectStatement)
        XCTAssertEqual(variables[0] as? String, expectedVariable)
    }
}
