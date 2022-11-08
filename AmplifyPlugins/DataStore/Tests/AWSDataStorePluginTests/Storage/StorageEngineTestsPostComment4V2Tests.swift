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
@testable import AWSDataStorePlugin

final class StorageEngineTestsPostComment4V2Tests: StorageEngineTestsBase, SharedTestCasesPostComment4V2 {

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
            
            ModelListDecoderRegistry.registerDecoder(DataStoreListDecoder.self)
            ModelProviderRegistry.registerDecoder(DataStoreModelDecoder.self)
            
            ModelRegistry.register(modelType: ParentPost4V2.self)
            ModelRegistry.register(modelType: ChildComment4V2.self)
            do {
                try storageEngine.setUp(modelSchemas: [ParentPost4V2.schema])
                try storageEngine.setUp(modelSchemas: [ChildComment4V2.schema])
            } catch {
                XCTFail("Failed to setup storage engine")
            }
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    func testSaveCommentThenQueryComment() async throws {
        let comment = ChildComment4V2(content: "content")
        let savedComment = try await saveAsync(comment)
        XCTAssertEqual(savedComment.id, comment.id)
        
        guard let queriedComment = try await queryAsync(ChildComment4V2.self,
                                                        byIdentifier: comment.id,
                                                        eagerLoad: true) else {
            XCTFail("Failed to query saved comment")
            return
        }
        XCTAssertEqual(queriedComment.id, comment.id)
    }
    
    func testSavePostThenQueryPost() async throws {
        let post = ParentPost4V2(title: "title")
        let savedPost = try await saveAsync(post)
        XCTAssertEqual(savedPost.id, post.id)
        
        guard let queriedPost = try await queryAsync(ParentPost4V2.self,
                                                     byIdentifier: post.id,
                                                     eagerLoad: true) else {
            XCTFail("Failed to query saved post")
            return
        }
        XCTAssertEqual(queriedPost.id, post.id)
    }
    
    func testSaveMultipleThenQueryComments() async throws {
        try await saveAsync(ChildComment4V2(content: "content"))
        try await saveAsync(ChildComment4V2(content: "content"))
        
        let comments = try await queryAsync(ChildComment4V2.self, eagerLoad: true)
        XCTAssertEqual(comments.count, 2)
    }
    
    func testSaveMultipleThenQueryPosts() async throws {
        try await saveAsync(ParentPost4V2(title: "title"))
        try await saveAsync(ParentPost4V2(title: "title"))
        
        let comments = try await queryAsync(ParentPost4V2.self, eagerLoad: true)
        XCTAssertEqual(comments.count, 2)
    }
    
    // TODO: clean up this test
    func testCommentWithPost_TranslateToStorageValues() async throws {
        let post = ParentPost4V2(id: "postId", title: "title")
        _ = try await saveAsync(post)
        var comment = ChildComment4V2(content: "content", post: post)
        
        // Model.sqlValues testing
        let sqlValues = comment.sqlValues(for: ChildComment4V2.schema.columns,
                                          modelSchema: ChildComment4V2.schema)
        XCTAssertEqual(sqlValues[0] as? String, comment.id)
        XCTAssertEqual(sqlValues[1] as? String, comment.content)
        XCTAssertNil(sqlValues[2]) // createdAt
        XCTAssertNil(sqlValues[3]) // updatedAt
        XCTAssertEqual(sqlValues[4] as? String, post.id)
        
        // InsertStatement testing
        let insertStatement = InsertStatement(model: comment,
                                              modelSchema: ChildComment4V2.schema)
        XCTAssertEqual(insertStatement.variables[0] as? String, comment.id)
        XCTAssertEqual(insertStatement.variables[1] as? String, comment.content)
        XCTAssertNil(insertStatement.variables[2]) // createdAt
        XCTAssertNil(insertStatement.variables[3]) // updatedAt
        XCTAssertEqual(insertStatement.variables[4] as? String, post.id)
        _ = try connection.prepare(insertStatement.stringValue).run(insertStatement.variables)
        
        // UpdateStatement testing
        comment.content = "updatedContent"
        let updateStatement = UpdateStatement(model: comment,
                                              modelSchema: ChildComment4V2.schema,
                                              condition: nil)
        _ = try connection.prepare(updateStatement.stringValue).run(updateStatement.variables)
        
        
        // Select
        let selectStatement = SelectStatement(from: ChildComment4V2.schema,
                                              predicate: field("id").eq(comment.id),
                                              sort: nil,
                                              paginationInput: nil,
                                              eagerLoad: true)
        let rows = try connection.prepare(selectStatement.stringValue).run(selectStatement.variables)
        print(rows)
        let result: [ModelValues] = try rows.convertToModelValues(to: ChildComment4V2.self,
                                                                  withSchema: ChildComment4V2.schema,
                                                                  using: selectStatement)
        print(result)
        XCTAssertEqual(result.count, 1)
        // asert content is "updatedContent"
    }
    
    func testSaveCommentWithPostThenQueryCommentAndAccessPost() async throws {
        let post = ParentPost4V2(title: "title")
        _ = try await saveAsync(post)
        let comment = ChildComment4V2(content: "content", post: post)
        _ = try await saveAsync(comment)
        
        guard let queriedComment = try await queryAsync(ChildComment4V2.self,
                                                        byIdentifier: comment.id,
                                                        eagerLoad: true) else {
            XCTFail("Failed to query saved comment")
            return
        }
        XCTAssertEqual(queriedComment.id, comment.id)
        guard let eagerLoadedPost = queriedComment.post else {
            XCTFail("post should be eager loaded")
            return
        }
        XCTAssertEqual(eagerLoadedPost.id, post.id)
    }
    
    func testSaveCommentWithPostThenQueryPostAndAccessComments() async throws {
        let post = ParentPost4V2(title: "title")
        _ = try await saveAsync(post)
        let comment = ChildComment4V2(content: "content", post: post)
        _ = try await saveAsync(comment)
        
        guard let queriedPost = try await queryAsync(ParentPost4V2.self,
                                                     byIdentifier: post.id,
                                                     eagerLoad: true) else {
            XCTFail("Failed to query saved post")
            return
        }
        XCTAssertEqual(queriedPost.id, post.id)
        guard let comments = queriedPost.comments else {
            XCTFail("Failed to get comments from queried post")
            return
        }

        switch comments.listProvider.getState() {
        case .notLoaded(let associatedId, let associatedField):
            XCTAssertEqual(associatedId, post.id)
            XCTAssertEqual(associatedField, "post")
        case .loaded(let comments):
            print("loaded comments \(comments)")
            XCTFail("Should not be loaded")
        }
    }
    
    func testSaveMultipleCommentWithPostThenQueryCommentsAndAccessPost() async throws {
        let post1 = try await saveAsync(ParentPost4V2(id: "postId1", title: "title1"))
        _ = try await saveAsync(ChildComment4V2(id: "id1", content: "content", post: post1))
        let post2 = try await saveAsync(ParentPost4V2(id: "postId2", title: "title2"))
        _ = try await saveAsync(ChildComment4V2(id: "id2", content: "content", post: post2))
        let comments = try await queryAsync(ChildComment4V2.self, eagerLoad: true)
        XCTAssertEqual(comments.count, 2)
        guard let comment1 = comments.first(where: { $0.id == "id1" }) else {
            XCTFail("Couldn't find comment with `id1`")
            return
        }
        guard let comment2 = comments.first(where: { $0.id == "id2" }) else {
            XCTFail("Couldn't find comment with `id2`")
            return
        }
        guard let post1 = comment1.post else {
            XCTFail("missing post on comment1")
            return
        }
        XCTAssertEqual(post1.id, "postId1")
        XCTAssertEqual(post1.title, "title1")
        guard let post2 = comment2.post else {
            XCTFail("missing post on comment2")
            return
        }
        XCTAssertEqual(post2.id, "postId2")
        XCTAssertEqual(post2.title, "title2")
    }
    
    func testSaveMultipleCommentWithPostThenQueryPostAndAccessComments() async throws {
        let post1 = try await saveAsync(ParentPost4V2(id: "postId1", title: "title1"))
        _ = try await saveAsync(ChildComment4V2(id: "id1", content: "content", post: post1))
        let post2 = try await saveAsync(ParentPost4V2(id: "postId2", title: "title2"))
        _ = try await saveAsync(ChildComment4V2(id: "id2", content: "content", post: post2))
        let posts = try await queryAsync(ParentPost4V2.self, eagerLoad: true)
        XCTAssertEqual(posts.count, 2)
        guard let postId1 = posts.first(where: { $0.id == "postId1" }) else {
            XCTFail("Couldn't find comment with `id1`")
            return
        }
        guard let postId2 = posts.first(where: { $0.id == "postId2" }) else {
            XCTFail("Couldn't find comment with `id2`")
            return
        }
        switch postId1.comments?.listProvider.getState() {
        case .notLoaded(let associatedId, let associatedField):
            XCTAssertEqual(associatedId, postId1.id)
            XCTAssertEqual(associatedField, "post")
        case .loaded:
            XCTFail("Should not be loaded")
        default:
            XCTFail("missing comments")
        }
        switch postId2.comments?.listProvider.getState() {
        case .notLoaded(let associatedId, let associatedField):
            XCTAssertEqual(associatedId, postId2.id)
            XCTAssertEqual(associatedField, "post")
        case .loaded:
            XCTFail("Should not be loaded")
        default:
            XCTFail("missing comments")
        }
    }
}
