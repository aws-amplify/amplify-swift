//
//  StorageEngineTestsLazyPostComment4V2Tests.swift
//  
//
//  Created by Law, Michael on 8/22/22.
//


import Foundation
import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

final class StorageEngineTestsLazyPostComment4V2Tests: StorageEngineTestsBase, SharedTestCasesPostComment4V2 {
    
    override func setUp() {
        super.setUp()
        Amplify.Logging.logLevel = .verbose
        
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
            
            ModelRegistry.register(modelType: LazyParentPost4V2.self)
            ModelRegistry.register(modelType: LazyChildComment4V2.self)
            do {
                try storageEngine.setUp(modelSchemas: [LazyParentPost4V2.schema])
                try storageEngine.setUp(modelSchemas: [LazyChildComment4V2.schema])
            } catch {
                XCTFail("Failed to setup storage engine")
            }
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }
    
    func testSaveCommentThenQueryComment() async throws {
        let comment = LazyChildComment4V2(content: "content")
        let savedComment = try await saveAsync(comment)
        XCTAssertEqual(savedComment.id, comment.id)
        switch savedComment._post.modelProvider.getState() {
        case .notLoaded:
            XCTFail("should be loaded, with `nil` element")
        case .loaded(let element):
            XCTAssertNil(element)
        }
        guard let queriedComment = try await queryAsync(LazyChildComment4V2.self,
                                                        byIdentifier: comment.id,
                                                        eagerLoad: true) else {
            XCTFail("Failed to query saved comment")
            return
        }
        XCTAssertEqual(queriedComment.id, queriedComment.id)
        switch queriedComment._post.modelProvider.getState() {
        case .notLoaded:
            XCTFail("should be loaded, with `nil` element")
        case .loaded(let element):
            XCTAssertNil(element)
        }
    }
    
    func testSavePostThenQueryPost() async throws {
        let post = LazyParentPost4V2(title: "title")
        let savedPost = try await saveAsync(post)
        XCTAssertEqual(savedPost.id, post.id)
        
        guard let queriedPost = try await queryAsync(LazyParentPost4V2.self,
                                                     byIdentifier: post.id,
                                                     eagerLoad: true) else {
            XCTFail("Failed to query saved post")
            return
        }
        XCTAssertEqual(queriedPost.id, queriedPost.id)
        switch queriedPost.comments?.listProvider.getState() {
        case .notLoaded(let associatedId, let associatedField):
            XCTAssertEqual(associatedId, post.id)
            XCTAssertEqual(associatedField, LazyChildComment4V2.CodingKeys.post.stringValue)
        case .loaded:
            XCTFail("Should be not loaded")
        default:
            XCTFail("missing comments")
        }
    }
    
    func testSaveMultipleThenQueryComments() async throws {
        try await saveAsync(LazyChildComment4V2(content: "content"))
        try await saveAsync(LazyChildComment4V2(content: "content"))
        
        let comments = try await queryAsync(LazyChildComment4V2.self,
                                            eagerLoad: true)
        XCTAssertEqual(comments.count, 2)
    }
    
    func testSaveMultipleThenQueryPosts() async throws {
        try await saveAsync(LazyParentPost4V2(title: "title"))
        try await saveAsync(LazyParentPost4V2(title: "title"))
        
        let comments = try await queryAsync(LazyParentPost4V2.self,
                                            eagerLoad: true)
        XCTAssertEqual(comments.count, 2)
    }
    
    func testCommentWithPost_TranslateToStorageValues() async throws {
        let post = LazyParentPost4V2(id: "postId", title: "title")
        _ = try await saveAsync(post)
        var comment = LazyChildComment4V2(content: "content", post: post)
        
        // Model.sqlValues tesitng
        let sqlValues = comment.sqlValues(for: LazyChildComment4V2.schema.columns,
                                          modelSchema: LazyChildComment4V2.schema)
        XCTAssertEqual(sqlValues[0] as? String, comment.id)
        XCTAssertEqual(sqlValues[1] as? String, comment.content)
        XCTAssertNil(sqlValues[2]) // createdAt
        XCTAssertNil(sqlValues[3]) // updatedAt
        XCTAssertEqual(sqlValues[4] as? String, post.id)
        
        // Insert
        let insertStatement = InsertStatement(model: comment, modelSchema: LazyChildComment4V2.schema)
        XCTAssertEqual(insertStatement.variables[0] as? String, comment.id)
        XCTAssertEqual(insertStatement.variables[1] as? String, comment.content)
        XCTAssertNil(insertStatement.variables[2]) // createdAt
        XCTAssertNil(insertStatement.variables[3]) // updatedAt
        XCTAssertEqual(insertStatement.variables[4] as? String, post.id)
        _ = try connection.prepare(insertStatement.stringValue).run(insertStatement.variables)
        
        // Update
        comment.content = "updatedContent"
        let updateStatement = UpdateStatement(model: comment,
                                              modelSchema: LazyChildComment4V2.schema,
                                              condition: nil)
        _ = try connection.prepare(updateStatement.stringValue).run(updateStatement.variables)
        
        // Select with eagerLoad true
        let selectStatement = SelectStatement(from: LazyChildComment4V2.schema,
                                              predicate: field("id").eq(comment.id),
                                              sort: nil,
                                              paginationInput: nil,
                                              eagerLoad: true)
        let rows = try connection.prepare(selectStatement.stringValue).run(selectStatement.variables)
        _ = try rows.convertToModelValues(to: LazyChildComment4V2.self,
                                          withSchema: LazyChildComment4V2.schema,
                                          using: selectStatement)
        let comments = try rows.convert(to: LazyChildComment4V2.self,
                                        withSchema: LazyChildComment4V2.schema,
                                        using: selectStatement)
        XCTAssertEqual(comments.count, 1)
        guard let comment = comments.first else {
            XCTFail("Should retrieve single comment")
            return
        }
        
        XCTAssertEqual(comment.content, "updatedContent")
        switch comment._post.modelProvider.getState() {
        case .notLoaded:
            XCTFail("Should have been loaded")
        case .loaded(let post):
            guard let post = post else {
                XCTFail("Loaded with no post")
                return
            }
            XCTAssertEqual(post.id, "postId")
            XCTAssertEqual(post.title, "title")
        }
        
        // Select with eagerLoad false
        let selectStatement2 = SelectStatement(from: LazyChildComment4V2.schema,
                                               predicate: field("id").eq(comment.id),
                                               sort: nil,
                                               paginationInput: nil,
                                               eagerLoad: false)
        let rows2 = try connection.prepare(selectStatement2.stringValue).run(selectStatement2.variables)
        _ = try rows2.convertToModelValues(to: LazyChildComment4V2.self,
                                           withSchema: LazyChildComment4V2.schema,
                                           using: selectStatement2,
                                           eagerLoad: false)
        let comments2 = try rows.convert(to: LazyChildComment4V2.self,
                                         withSchema: LazyChildComment4V2.schema,
                                         using: selectStatement2,
                                         eagerLoad: false)
        XCTAssertEqual(comments.count, 1)
        guard let comment2 = comments2.first else {
            XCTFail("Should retrieve single comment")
            return
        }

        XCTAssertEqual(comment2.content, "updatedContent")
        switch comment2._post.modelProvider.getState() {
        case .notLoaded(let identifiers):
            XCTAssertEqual(identifiers["id"], "postId")
        case .loaded:
            XCTFail("Should be not loaded")
        }
    }
    
    func testSaveCommentWithPostThenQueryCommentAndAccessPost() async throws {
        let post = LazyParentPost4V2(title: "title")
        try await saveAsync(post)
        let comment = LazyChildComment4V2(content: "content", post: post)
        let savedComment = try await saveAsync(comment)
        
        // The post should be eager loaded by default on a save
        switch savedComment._post.modelProvider.getState() {
        case .notLoaded:
            XCTFail("eager loaded post should be loaded")
        case .loaded(let element):
            guard let loadedPost = element else {
                XCTFail("post is missing from the loaded state of LazyModel")
                return
            }
            XCTAssertEqual(loadedPost.id, post.id)
        }
        
        // The query with eagerLoad should load the post
        guard let queriedCommentEagerLoadedPost = try await queryAsync(LazyChildComment4V2.self,
                                                                       byIdentifier: comment.id,
                                                                       eagerLoad: true) else {
            XCTFail("Failed to query saved comment")
            return
        }
        switch queriedCommentEagerLoadedPost._post.modelProvider.getState() {
        case .notLoaded:
            XCTFail("eager loaded post should be loaded")
        case .loaded(let element):
            guard let loadedPost = element else {
                XCTFail("post is missing from the loaded state of LazyModel")
                return
            }
            XCTAssertEqual(loadedPost.id, post.id)
        }
    
        // The query with eagerLoad false should create a not loaded post for lazy loading
        guard let queriedCommentLazyLoadedPost = try await queryAsync(LazyChildComment4V2.self,
                                                                      byIdentifier: comment.id,
                                                                      eagerLoad: false) else {
            XCTFail("Failed to query saved comment")
            return
        }
        switch queriedCommentLazyLoadedPost._post.modelProvider.getState() {
        case .notLoaded(let identifiers):
            XCTAssertEqual(identifiers["id"], post.id)
        case .loaded:
            XCTFail("lazy loaded post should be not loaded")
        }
    }
    
    func testSaveCommentWithPostThenQueryPostAndAccessComments() async throws {
        let post = LazyParentPost4V2(title: "title")
        try await saveAsync(post)
        let comment = LazyChildComment4V2(content: "content", post: post)
        try await saveAsync(comment)
        
        guard let queriedPost = try await queryAsync(LazyParentPost4V2.self,
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
        case .loaded:
            XCTFail("Should not be loaded")
        }
    }
    
    func testSaveMultipleCommentWithPostThenQueryCommentsAndAccessPost() async throws {
        let post1 = LazyParentPost4V2(id: "postId1", title: "title1")
        try await saveAsync(post1)
        let comment1 = LazyChildComment4V2(id: "id1", content: "content", post: post1)
        try await saveAsync(comment1)
        let post2 = LazyParentPost4V2(id: "postId2", title: "title2")
        try await saveAsync(post2)
        var comment2 = LazyChildComment4V2(id: "id2", content: "content")
        comment2.setPost(post2)
        try await saveAsync(comment2)

        // Query with eagerLoad true
        var comments = try await queryAsync(LazyChildComment4V2.self,
                                            eagerLoad: true)

        XCTAssertEqual(comments.count, 2)
        guard let comment1 = comments.first(where: { $0.id == "id1" }) else {
            XCTFail("Couldn't find comment with `id1`")
            return
        }
        guard let comment2 = comments.first(where: { $0.id == "id2" }) else {
            XCTFail("Couldn't find comment with `id2`")
            return
        }
        switch comment1._post.modelProvider.getState() {
        case .notLoaded:
            XCTFail("Should be loaded")
        case .loaded(let post):
            XCTAssertEqual(post!.id, "postId1")
            XCTAssertEqual(post!.title, "title1")
        }
        switch comment2._post.modelProvider.getState() {
        case .notLoaded:
            XCTFail("Should be loaded")
        case .loaded(let post):
            XCTAssertEqual(post!.id, "postId2")
            XCTAssertEqual(post!.title, "title2")
        }
        
        // Query with eagerLoad false
        comments = try await queryAsync(LazyChildComment4V2.self,
                                            eagerLoad: false)

        XCTAssertEqual(comments.count, 2)
        guard let comment1 = comments.first(where: { $0.id == "id1" }) else {
            XCTFail("Couldn't find comment with `id1`")
            return
        }
        guard let comment2 = comments.first(where: { $0.id == "id2" }) else {
            XCTFail("Couldn't find comment with `id2`")
            return
        }
        switch comment1._post.modelProvider.getState() {
        case .notLoaded(let identifiers):
            XCTAssertEqual(identifiers["id"], "postId1")
        case .loaded:
            XCTFail("Should be not loaded")
        }
        switch comment2._post.modelProvider.getState() {
        case .notLoaded(let identifiers):
            XCTAssertEqual(identifiers["id"], "postId2")
        case .loaded:
            XCTFail("Should be not loaded")
        }
    }
    
    func testSaveMultipleCommentWithPostThenQueryPostAndAccessComments() async throws {
        let post1 = LazyParentPost4V2(id: "postId1", title: "title1")
        try await saveAsync(post1)
        let comment1 = LazyChildComment4V2(id: "id1", content: "content", post: post1)
        try await saveAsync(comment1)
        let post2 = LazyParentPost4V2(id: "postId2", title: "title2")
        try await saveAsync(post2)
        let comment2 = LazyChildComment4V2(id: "id2", content: "content", post: post2)
        try await saveAsync(comment2)
        
        var posts = try await queryAsync(LazyParentPost4V2.self)
        XCTAssertEqual(posts.count, 2)
        guard let postId1 = posts.first(where: { $0.id == "postId1" }) else {
            XCTFail("Couldn't find post with `postId1`")
            return
        }
        guard let postId2 = posts.first(where: { $0.id == "postId2" }) else {
            XCTFail("Couldn't find post with `postId2`")
            return
        }
        guard let comments1 = postId1.comments else {
            XCTFail("Failed to get comments from post1")
            return
        }
        
        switch comments1.listProvider.getState() {
        case .notLoaded(let associatedId, let associatedField):
            XCTAssertEqual(associatedId, post1.id)
            XCTAssertEqual(associatedField, "post")
        case .loaded:
            XCTFail("Should not be loaded")
        }
        
        guard let comments2 = postId2.comments else {
            XCTFail("Failed to get comments from post2")
            return
        }
        switch comments2.listProvider.getState() {
        case .notLoaded(let associatedId, let associatedField):
            XCTAssertEqual(associatedId, post2.id)
            XCTAssertEqual(associatedField, "post")
        case .loaded:
            XCTFail("Should not be loaded")
        }
    }
}

