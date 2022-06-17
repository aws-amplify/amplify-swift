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

class StorageEngineTestsOptionalAssociation: StorageEngineTestsBase {

    override func setUp() {
        super.setUp()
        Amplify.Logging.logLevel = .warn

        let validAPIPluginKey = "MockAPICategoryPlugin"
        let validAuthPluginKey = "MockAuthCategoryPlugin"
        do {
            connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)

            syncEngine = MockRemoteSyncEngine()
            storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                          dataStoreConfiguration: .default,
                                          syncEngine: syncEngine,
                                          validAPIPluginKey: validAPIPluginKey,
                                          validAuthPluginKey: validAuthPluginKey)
            ModelRegistry.register(modelType: Blog8.self)
            ModelRegistry.register(modelType: Post8.self)
            ModelRegistry.register(modelType: Comment8.self)
            do {
                try storageEngine.setUp(modelSchemas: [Blog8.schema])
                try storageEngine.setUp(modelSchemas: [Post8.schema])
                try storageEngine.setUp(modelSchemas: [Comment8.schema])
            } catch {
                XCTFail("Failed to setup storage engine")
            }
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    func testSaveCommentThenQuery() {
        let comment = Comment8(content: "content")
        guard case .success = saveModelSynchronous(model: comment) else {
            XCTFail("Failed to save comment")
            return
        }

        guard case let .success(queriedComment) =
            querySingleModelSynchronous(modelType: Comment8.self,
                                        predicate: Comment8.keys.id == comment.id) else {
                XCTFail("Failed to query post")
                return
        }
        XCTAssertEqual(queriedComment.id, comment.id)
        XCTAssertNil(queriedComment.post)
    }

    func testSavePostThenQuery() {
        let post = Post8(name: "name", randomId: "random", blog: nil)
        guard case .success = saveModelSynchronous(model: post) else {
            XCTFail("Failed to save post")
            return
        }

        guard case let .success(queriedPost) =
            querySingleModelSynchronous(modelType: Post8.self,
                                        predicate: Post8.keys.id == post.id) else {
                XCTFail("Failed to query post")
                return
        }
        XCTAssertEqual(queriedPost.id, post.id)
        XCTAssertNil(queriedPost.blog)
    }

    func testSaveBlogThenQuery() {
        let nestedModel = MyNestedModel8(id: UUID().uuidString, nestedName: "nestedName", notes: ["notes1", "notes2"])
        let customModel = MyCustomModel8(id: UUID().uuidString, name: "name", desc: "desc", children: [nestedModel])
        let blog = Blog8(name: "name", customs: [customModel], notes: ["notes1", "notes2"])
        guard case .success = saveModelSynchronous(model: blog) else {
            XCTFail("Failed to save blog")
            return
        }

        guard case let .success(queriedBlog) =
            querySingleModelSynchronous(modelType: Blog8.self,
                                        predicate: Blog8.keys.id == blog.id) else {
                XCTFail("Failed to query blog")
                return
        }
        XCTAssertEqual(queriedBlog.id, blog.id)
        XCTAssertEqual(queriedBlog.customs![0]?.id, customModel.id)
        XCTAssertEqual(queriedBlog.customs![0]?.children![0]?.id, nestedModel.id)
    }

    func testUpdateCommentWithPostThenQuery() {
        var comment = Comment8(content: "content")
        guard case .success = saveModelSynchronous(model: comment) else {
            XCTFail("Failed to save comment")
            return
        }
        let post = Post8(name: "name", randomId: "random", blog: nil)
        guard case .success = saveModelSynchronous(model: post) else {
            XCTFail("Failed to save post")
            return
        }
        comment.post = post
        guard case .success = saveModelSynchronous(model: comment) else {
            XCTFail("Failed to save comment")
            return
        }
        guard case let .success(queriedComment) =
            querySingleModelSynchronous(modelType: Comment8.self,
                                        predicate: Comment8.keys.id == comment.id) else {
                XCTFail("Failed to query post")
                return
        }
        XCTAssertEqual(queriedComment.id, comment.id)
        XCTAssertEqual(queriedComment.post?.id, post.id)
    }

    func testUpdatePostWithBlogThenQueryAndLazyLoad() {
        var post = Post8(name: "name", randomId: "random", blog: nil)
        guard case .success = saveModelSynchronous(model: post) else {
            XCTFail("Failed to save post")
            return
        }
        let nestedModel = MyNestedModel8(id: UUID().uuidString, nestedName: "nestedName", notes: ["notes1", "notes2"])
        let customModel = MyCustomModel8(id: UUID().uuidString, name: "name", desc: "desc", children: [nestedModel])
        let blog = Blog8(name: "name", customs: [customModel], notes: ["notes1", "notes2"])
        guard case .success = saveModelSynchronous(model: blog) else {
            XCTFail("Failed to save blog")
            return
        }
        post.blog = blog
        guard case .success = saveModelSynchronous(model: post) else {
            XCTFail("Failed to save post")
            return
        }

        guard case let .success(updatedPost) =
            querySingleModelSynchronous(modelType: Post8.self,
                                        predicate: Post8.keys.id == post.id) else {
                XCTFail("Failed to query post")
                return
        }
        XCTAssertEqual(updatedPost.id, post.id)
        XCTAssertNotNil(updatedPost.blog)
        XCTAssertEqual(updatedPost.blog?.id, blog.id)
        XCTAssertEqual(updatedPost.blog?.customs![0]?.id, customModel.id)
        XCTAssertEqual(updatedPost.blog?.customs![0]?.children![0]?.id, nestedModel.id)
    }

    func testUpdateCommentWithPostAndBlog() {
        let nestedModel = MyNestedModel8(id: UUID().uuidString, nestedName: "nestedName", notes: ["notes1", "notes2"])
        let customModel = MyCustomModel8(id: UUID().uuidString, name: "name", desc: "desc", children: [nestedModel])
        let blog = Blog8(name: "name", customs: [customModel], notes: ["notes1", "notes2"])
        guard case .success = saveModelSynchronous(model: blog) else {
            XCTFail("Failed to save blog")
            return
        }
        let post = Post8(name: "name", randomId: "random", blog: blog)
        guard case .success = saveModelSynchronous(model: post) else {
            XCTFail("Failed to save post")
            return
        }
        let comment = Comment8(content: "content", post: post)
        guard case .success = saveModelSynchronous(model: comment) else {
            XCTFail("Failed to save comment")
            return
        }

        guard case let .success(queriedComment) =
            querySingleModelSynchronous(modelType: Comment8.self,
                                        predicate: Comment8.keys.id == comment.id) else {
                XCTFail("Failed to query comment")
                return
        }
        XCTAssertEqual(queriedComment.id, comment.id)
        XCTAssertEqual(queriedComment.post?.id, post.id)
        XCTAssertEqual(queriedComment.post?.blog?.id, blog.id)
    }

    func testRemovePostFromCommentAndBlogFromPost() {
        let nestedModel = MyNestedModel8(id: UUID().uuidString, nestedName: "nestedName", notes: ["notes1", "notes2"])
        let customModel = MyCustomModel8(id: UUID().uuidString, name: "name", desc: "desc", children: [nestedModel])
        let blog = Blog8(name: "name", customs: [customModel], notes: ["notes1", "notes2"])
        var post = Post8(name: "name", randomId: "random", blog: blog)
        var comment = Comment8(content: "content", post: post)
        guard case .success = saveModelSynchronous(model: blog),
              case .success = saveModelSynchronous(model: post),
              case .success = saveModelSynchronous(model: comment) else {
            XCTFail("Failed to save blog, post, comment")
            return
        }
        guard case let .success(queriedComment) =
            querySingleModelSynchronous(modelType: Comment8.self,
                                        predicate: Comment8.keys.id == comment.id) else {
                XCTFail("Failed to query comment")
                return
        }
        XCTAssertEqual(queriedComment.id, comment.id)
        XCTAssertEqual(queriedComment.post?.id, post.id)
        XCTAssertEqual(queriedComment.post?.blog?.id, blog.id)
        comment.post = nil
        guard case .success = saveModelSynchronous(model: comment) else {
            XCTFail("Failed to save comment")
            return
        }
        guard case let .success(queriedComment) =
            querySingleModelSynchronous(modelType: Comment8.self,
                                        predicate: Comment8.keys.id == comment.id) else {
                XCTFail("Failed to query comment")
                return
        }
        XCTAssertNil(queriedComment.post)
        post.blog = nil
        guard case .success = saveModelSynchronous(model: post) else {
            XCTFail("Failed to save post")
            return
        }
        guard case let .success(queriedPost) =
            querySingleModelSynchronous(modelType: Post8.self,
                                        predicate: Post8.keys.id == post.id) else {
                XCTFail("Failed to query post")
                return
        }
        XCTAssertNil(queriedPost.blog)
    }

    func testPostSelectStatement() throws {
        let post = Post8(name: "name", randomId: "random", blog: nil)
        guard case .success = saveModelSynchronous(model: post) else {
            XCTFail("Failed to save post")
            return
        }
        let statement = SelectStatement(from: Post8.schema,
                                        predicate: nil,
                                        sort: nil,
                                        paginationInput: nil)
        let rows = try connection.prepare(statement.stringValue).run(statement.variables)
        // Eager loading selects all fields and associated fields. The number of columns is the number of fields of
        // Post8 plus it's associated field Blog8. This excludes the association itself, ie. post.blog is excluded
        // and blog.posts is excluded. So there are 6 Post8 fields and 6 Blog8 fields.
        XCTAssertEqual(rows.columnCount, 12)
        let results: [Post8] = try rows.convert(to: Post8.self,
                                                withSchema: Post8.schema,
                                                using: statement)

        XCTAssertNotNil(results)
        // The result is the single post which was saved and queried
        XCTAssertEqual(results.count, 1)
        XCTAssertNil(results.first!.blog)
    }

    func testPostWithBlogSelectStatement() throws {
        var post = Post8(name: "name", randomId: "random", blog: nil)
        guard case .success = saveModelSynchronous(model: post) else {
            XCTFail("Failed to save post")
            return
        }
        let blog = Blog8(name: "name", customs: nil, notes: nil)
        guard case .success = saveModelSynchronous(model: blog) else {
            XCTFail("Failed to save blog")
            return
        }
        post.blog = blog
        guard case .success = saveModelSynchronous(model: post) else {
            XCTFail("Failed to save post")
            return
        }

        let statement = SelectStatement(from: Post8.schema,
                                        predicate: nil,
                                        sort: nil,
                                        paginationInput: nil)
        let rows = try connection.prepare(statement.stringValue).run(statement.variables)
        let results: [Post8] = try rows.convert(to: Post8.self,
                                                withSchema: Post8.schema,
                                                using: statement)

        XCTAssertNotNil(results)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.blog?.id, blog.id)
    }
}
