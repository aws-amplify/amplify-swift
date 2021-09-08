//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin
@testable import AWSPluginsCore

// swiftlint:disable type_body_length
class ModelCompareTests: BaseDataStoreTests {

    func testPostsAreEqual() {
        let id = UUID().uuidString
        let createdAt = Temporal.DateTime.now()
        let title = "MyFirstPost"
        let content = "This is my first post."
        let draft = false
        let rating = 4.0
        let status = PostStatus.published
        let post1 = Post(id: id,
                         title: title,
                         content: content,
                         createdAt: createdAt,
                         draft: draft,
                         rating: rating,
                         status: status)
        let post2 = Post(id: id,
                         title: title,
                         content: content,
                         createdAt: createdAt,
                         draft: draft,
                         rating: rating,
                         status: status)
        XCTAssertTrue(Post.schema.isEqual(post1, post2))
    }

    func testPostsAreEqualWithSameCollection() {
        let id = UUID().uuidString
        let createdAt = Temporal.DateTime.now()
        let title = "MyFirstPost"
        let content = "This is my first post."
        let draft = false
        let rating = 4.0
        let status = PostStatus.published
        var post1 = Post(id: id,
                         title: title,
                         content: content,
                         createdAt: createdAt,
                         draft: draft,
                         rating: rating,
                         status: status)
        var post2 = Post(id: id,
                         title: title,
                         content: content,
                         createdAt: createdAt,
                         draft: draft,
                         rating: rating,
                         status: status)
        let commentId = UUID().uuidString
        let comment1 = Comment(id: commentId, content: "This is a comment.", createdAt: createdAt, post: post1)
        let comment2 = Comment(id: commentId, content: "This is a comment.", createdAt: createdAt, post: post2)
        post1.comments = [comment1]
        post2.comments = [comment2]
        XCTAssertTrue(Post.schema.isEqual(post1, post2))
    }

    func testCommentsAreEqualWithDifferentPosts() {
        let createdAt = Temporal.DateTime.now()
        let title = "MyFirstPost"
        let content = "This is my first post."
        let draft = false
        let rating = 4.0
        let status = PostStatus.published

        // creating posts with different id
        var post1 = Post(id: UUID().uuidString,
                         title: title,
                         content: content,
                         createdAt: createdAt,
                         draft: draft,
                         rating: rating,
                         status: status)
        var post2 = Post(id: UUID().uuidString,
                         title: title,
                         content: content,
                         createdAt: createdAt,
                         draft: draft,
                         rating: rating,
                         status: status)
        let id = UUID().uuidString
        let comment1 = Comment(id: id, content: "This is a comment.", createdAt: createdAt, post: post1)
        let comment2 = Comment(id: id, content: "This is a comment.", createdAt: createdAt, post: post2)
        post1.comments = [comment1]
        post2.comments = [comment2]
        XCTAssertTrue(Comment.schema.isEqual(comment1, comment2))
    }

    func testPostsAreNotEqualWithNilFields() {
        let id = UUID().uuidString
        let createdAt = Temporal.DateTime.now()
        let title = "MyFirstPost"
        let content = "This is my first post."
        let draft = false
        let rating = 4.0
        let status = PostStatus.published
        let post1 = Post(id: id,
                         title: title,
                         content: content,
                         createdAt: createdAt,
                         draft: draft,
                         rating: rating,
                         status: status)

        // rating is nil
        let post2 = Post(id: id,
                         title: title,
                         content: content,
                         createdAt: createdAt,
                         draft: draft,
                         rating: nil,
                         status: status)
        XCTAssertFalse(Post.schema.isEqual(post1, post2))
    }

    func testPostsAreNotEqualWithDifferentId() {
        let createdAt = Temporal.DateTime.now()
        let title = "MyFirstPost"
        let content = "This is my first post."
        let draft = false
        let rating = 4.0
        let status = PostStatus.published
        let post1 = Post(id: UUID().uuidString,
                         title: title,
                         content: content,
                         createdAt: createdAt,
                         draft: draft,
                         rating: rating,
                         status: status)
        let post2 = Post(id: UUID().uuidString,
                         title: title,
                         content: content,
                         createdAt: createdAt,
                         draft: draft,
                         rating: rating,
                         status: status)
        XCTAssertFalse(Post.schema.isEqual(post1, post2))
    }

    func testPostsAreNotEqualWithDifferentStringField() {
        let id = UUID().uuidString
        let createdAt = Temporal.DateTime.now()
        let title1 = "MyFirstPost"
        let title2 = "MySecondPost"
        let content = "This is my first post."
        let draft = false
        let rating = 4.0
        let status = PostStatus.published
        let post1 = Post(id: id,
                         title: title1,
                         content: content,
                         createdAt: createdAt,
                         draft: draft,
                         rating: rating,
                         status: status)
        let post2 = Post(id: id,
                         title: title2,
                         content: content,
                         createdAt: createdAt,
                         draft: draft,
                         rating: rating,
                         status: status)
        XCTAssertFalse(Post.schema.isEqual(post1, post2))
    }

    func testPostsAreNotEqualWithDifferentDoubleField() {
        let id = UUID().uuidString
        let createdAt = Temporal.DateTime.now()
        let title = "MyFirstPost"
        let content = "This is my first post."
        let draft = false
        let rating1 = 4.0
        let rating2 = 1.0
        let status = PostStatus.published
        let post1 = Post(id: id,
                         title: title,
                         content: content,
                         createdAt: createdAt,
                         draft: draft,
                         rating: rating1,
                         status: status)
        let post2 = Post(id: id,
                         title: title,
                         content: content,
                         createdAt: createdAt,
                         draft: draft,
                         rating: rating2,
                         status: status)
        XCTAssertFalse(Post.schema.isEqual(post1, post2))
    }

    func testPostsAreNotEqualWithDifferentDateField() {
        let id = UUID().uuidString
        let title = "MyFirstPost"
        let content = "This is my first post."
        let draft = false
        let rating = 4.0
        let status = PostStatus.published
        let formatter = DateFormatter()
        formatter.dateFormat = TemporalFormat.short.dateFormat
        let createdAt1 = Temporal.DateTime(formatter.date(from: "2021-09-01")!)
        let createdAt2 = Temporal.DateTime(formatter.date(from: "2020-09-01")!)
        let post1 = Post(id: id,
                         title: title,
                         content: content,
                         createdAt: createdAt1,
                         draft: draft,
                         rating: rating,
                         status: status)
        let post2 = Post(id: id,
                         title: title,
                         content: content,
                         createdAt: createdAt2,
                         draft: draft,
                         rating: rating,
                         status: status)
        XCTAssertFalse(Post.schema.isEqual(post1, post2))
    }

    func testPostsAreNotEqualWithDifferentEnumField() {
        let id = UUID().uuidString
        let createdAt = Temporal.DateTime.now()
        let title = "MyFirstPost"
        let content = "This is my first post."
        let draft = false
        let rating = 4.0
        let status1 = PostStatus.published
        let status2 = PostStatus.draft
        let post1 = Post(id: id,
                         title: title,
                         content: content,
                         createdAt: createdAt,
                         draft: draft,
                         rating: rating,
                         status: status1)
        let post2 = Post(id: id,
                         title: title,
                         content: content,
                         createdAt: createdAt,
                         draft: draft,
                         rating: rating,
                         status: status2)
        XCTAssertFalse(Post.schema.isEqual(post1, post2))
    }

    func testPostsAreNotEqualWithDifferentBoolField() {
        let id = UUID().uuidString
        let createdAt = Temporal.DateTime.now()
        let title = "MyFirstPost"
        let content = "This is my first post."
        let draft1 = false
        let draft2 = true
        let rating = 4.0
        let status = PostStatus.published
        let post1 = Post(id: id,
                         title: title,
                         content: content,
                         createdAt: createdAt,
                         draft: draft1,
                         rating: rating,
                         status: status)
        let post2 = Post(id: id,
                         title: title,
                         content: content,
                         createdAt: createdAt,
                         draft: draft2,
                         rating: rating,
                         status: status)
        XCTAssertFalse(Post.schema.isEqual(post1, post2))
    }

    func testTodosAreEqualWithSameEmbeddedable() {
        let id = UUID().uuidString
        let name = "MyTodo"
        let section = Section(name: "MySection", number: 10)
        let todo1 = Todo(id: id, name: name, section: section)
        let todo2 = Todo(id: id, name: name, section: section)
        XCTAssertTrue(Todo.schema.isEqual(todo1, todo2))
    }

    func testTodosAreNotEqualWithDifferentEmbeddedable() {
        let id = UUID().uuidString
        let name = "MyTodo"
        let section1 = Section(name: "MySection1", number: 10)
        let section2 = Section(name: "MySection2", number: 20)
        let todo1 = Todo(id: id, name: name, section: section1)
        let todo2 = Todo(id: id, name: name, section: section2)
        XCTAssertFalse(Todo.schema.isEqual(todo1, todo2))
    }

    func testTodosAreEqualWithSameEmbeddedableCollection() {
        let id = UUID().uuidString
        let name = "MyTodo"
        let color1 = Color(name: "Color1", red: 100, green: 100, blue: 100)
        let color2 = Color(name: "Color2", red: 200, green: 200, blue: 200)
        let category1 = Category(name: "Category1", color: color1)
        let category2 = Category(name: "Category1", color: color2)
        let todo1 = Todo(id: id, name: name, categories: [category1, category2])
        let todo2 = Todo(id: id, name: name, categories: [category1, category2])
        XCTAssertTrue(Todo.schema.isEqual(todo1, todo2))
    }

    func testTodosAreNotEqualWithDifferentEmbeddedableCollection() {
        let id = UUID().uuidString
        let name = "MyTodo"
        let color1 = Color(name: "Color1", red: 100, green: 100, blue: 100)
        let color2 = Color(name: "Color2", red: 200, green: 200, blue: 200)
        let category1 = Category(name: "Category1", color: color1)
        let category2 = Category(name: "Category1", color: color2)
        let todo1 = Todo(id: id, name: name, categories: [category1])
        let todo2 = Todo(id: id, name: name, categories: [category2])
        XCTAssertFalse(Todo.schema.isEqual(todo1, todo2))
    }

    // This tests for equality when two models have different read only fields.
    // In this case, `createdAt` is a read only field.
    func testRecordCoversAreEqualWithDifferentReadOnlyFields() {
        let id = UUID().uuidString
        let artist = "Artist"
        let formatter = DateFormatter()
        formatter.dateFormat = TemporalFormat.short.dateFormat
        let createdAt1 = Temporal.DateTime(formatter.date(from: "2021-09-01")!)
        let createdAt2 = Temporal.DateTime(formatter.date(from: "2020-09-01")!)
        let recordCover1 = RecordCover(id: id, artist: artist, createdAt: createdAt1)
        let recordCover2 = RecordCover(id: id, artist: artist, createdAt: createdAt2)
        XCTAssertTrue(RecordCover.schema.isEqual(recordCover1, recordCover2))
    }
}
