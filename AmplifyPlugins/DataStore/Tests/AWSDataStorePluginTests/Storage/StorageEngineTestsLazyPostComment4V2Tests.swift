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


final class StorageEngineTestsLazyPostComment4V2Tests: StorageEngineTestsBase {
    
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
    
    func testQueryComment() async throws {
        let comment = LazyChildComment4V2(content: "content")
        _ = try await saveAsync(comment)
        
        guard (try await queryAsync(LazyChildComment4V2.self,
                                    byIdentifier: comment.id)) != nil else {
            XCTFail("Failed to query saved comment")
            return
        }
    }
    
    func testQueryPost() async throws {
        let post = LazyParentPost4V2(title: "title")
        _ = try await saveAsync(post)
        
        guard (try await queryAsync(LazyParentPost4V2.self,
                                    byIdentifier: post.id)) != nil else {
            XCTFail("Failed to query saved post")
            return
        }
    }
    
    func testQueryListComments() async throws {
        _ = try await saveAsync(LazyChildComment4V2(content: "content"))
        _ = try await saveAsync(LazyChildComment4V2(content: "content"))
        
        let comments = try await queryAsync(LazyChildComment4V2.self)
        XCTAssertEqual(comments.count, 2)
    }
    
    func testQueryListPosts() async throws {
        _ = try await saveAsync(LazyParentPost4V2(title: "title"))
        _ = try await saveAsync(LazyParentPost4V2(title: "title"))
        
        let comments = try await queryAsync(LazyParentPost4V2.self)
        XCTAssertEqual(comments.count, 2)
    }
    
    func testPostHasLazyLoadedComments() async throws {
        let post = LazyParentPost4V2(title: "title")
        _ = try await saveAsync(post)
        let comment = LazyChildComment4V2(content: "content", post: post)
        _ = try await saveAsync(comment)
        
        guard let queriedPost = try await queryAsync(LazyParentPost4V2.self,
                                                     byIdentifier: post.id) else {
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
            XCTFail("Should not be loaded")
        }
    }
    
    func testCommentHasEagerLoadedPost_InsertUpdateSelect() async throws {
        let post = LazyParentPost4V2(id: "postId", title: "title")
        _ = try await saveAsync(post)
        var comment = LazyChildComment4V2(content: "content", post: post)
        
        // Insert
        let insertStatement = InsertStatement(model: comment, modelSchema: LazyChildComment4V2.schema)
        XCTAssertEqual(insertStatement.variables[4] as? String, post.id)
        _ = try connection.prepare(insertStatement.stringValue).run(insertStatement.variables)
        
        // Update
        comment.content = "updatedContent"
        let updateStatement = UpdateStatement(model: comment,
                                              modelSchema: LazyChildComment4V2.schema,
                                              condition: nil)
        _ = try connection.prepare(updateStatement.stringValue).run(updateStatement.variables)
        
        // Select
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
        guard let eagerLoadedPost = comment.post else {
            XCTFail("post should be decoded")
            return
        }
        switch eagerLoadedPost.modelProvider.getState() {
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
    }
    
    func testCommentHasEagerLoadedPost_StorageEngineAdapterSQLite() async throws {
        let post = LazyParentPost4V2(id: "postId", title: "title")
        _ = try await saveAsync(post)
        let comment = LazyChildComment4V2(content: "content", post: post)
        _ = try await saveAsync(comment)
        
        guard let queriedComment = try await queryStorageAdapter(LazyChildComment4V2.self,
                                                                 byIdentifier: comment.id) else {
            XCTFail("Failed to query saved comment")
            return
        }
        XCTAssertEqual(queriedComment.id, comment.id)
        guard let eagerLoadedPost = queriedComment.post else {
            XCTFail("post should be decoded")
            return
        }
        switch eagerLoadedPost.modelProvider.getState() {
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
    }
    
    // Loading the comments should also eager load the post since `eagerLoad` is true by default. `eagerLoad`
    // controls whether nested data is fetched using the SQL join statements.
    func testCommentHasEagerLoadedPost_StorageEngine() async throws {
        let post = LazyParentPost4V2(id: "postId", title: "title")
        _ = try await saveAsync(post)
        let comment = LazyChildComment4V2(content: "content", post: post)
        _ = try await saveAsync(comment)
        
        guard let queriedComment = try await queryAsync(LazyChildComment4V2.self,
                                                        byIdentifier: comment.id) else {
            XCTFail("Failed to query saved comment")
            return
        }
        XCTAssertEqual(queriedComment.id, comment.id)
        guard let eagerLoadedPost = queriedComment.post else {
            XCTFail("post should be decoded")
            return
        }
        switch eagerLoadedPost.modelProvider.getState() {
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
    }
    
    func testCommentHasLazyLoadedPost_InsertUpdateSelect() async throws {
        let eagerLoad = false
        let post = LazyParentPost4V2(id: "postId", title: "title")
        _ = try await saveAsync(post)
        var comment = LazyChildComment4V2(content: "content", post: post)
        
        // Insert
        let insertStatement = InsertStatement(model: comment, modelSchema: LazyChildComment4V2.schema)
        XCTAssertEqual(insertStatement.variables[4] as? String, post.id)
        _ = try connection.prepare(insertStatement.stringValue).run(insertStatement.variables)
        
        // Update
        comment.content = "updatedContent"
        let updateStatement = UpdateStatement(model: comment,
                                              modelSchema: LazyChildComment4V2.schema,
                                              condition: nil)
        _ = try connection.prepare(updateStatement.stringValue).run(updateStatement.variables)
        
        // Select
        let selectStatement = SelectStatement(from: LazyChildComment4V2.schema,
                                              predicate: field("id").eq(comment.id),
                                              sort: nil,
                                              paginationInput: nil,
                                              eagerLoad: eagerLoad)
        let rows = try connection.prepare(selectStatement.stringValue).run(selectStatement.variables)
        let modelJSON = try rows.convertToModelValues(to: LazyChildComment4V2.self,
                                                      withSchema: LazyChildComment4V2.schema,
                                                      using: selectStatement,
                                                      eagerLoad: eagerLoad)
        let comments = try rows.convert(to: LazyChildComment4V2.self,
                                        withSchema: LazyChildComment4V2.schema,
                                        using: selectStatement,
                                        eagerLoad: eagerLoad)
        XCTAssertEqual(comments.count, 1)
        guard let comment = comments.first else {
            XCTFail("Should retrieve single comment")
            return
        }

        XCTAssertEqual(comment.content, "updatedContent")
        guard let lazyLoadedPost = comment.post else {
            XCTFail("post should be decoded")
            return
        }
        switch lazyLoadedPost.modelProvider.getState() {
        case .notLoaded(let id):
            XCTAssertEqual(id, "postId")
        case .loaded:
            XCTFail("Should be not loaded")
        }
    }
    
    // Loading the comments should lazy load the post when `eagerLoad` is explicitly set to false. This will stop the
    // SQL join statements from being added and only store the
    func testCommentHasLazyLoadPost() async throws {
        let post = LazyParentPost4V2(id: "postId", title: "title")
        _ = try await saveAsync(post)
        let comment = LazyChildComment4V2(content: "content", post: post)
        _ = try await saveAsync(comment)
        
        guard let queriedComment = try await queryAsync(LazyChildComment4V2.self,
                                                        byIdentifier: comment.id,
                                                        eagerLoad: false) else {
            XCTFail("Failed to query saved comment")
            return
        }
        XCTAssertEqual(queriedComment.id, comment.id)
        guard let lazyLoadedPost = queriedComment.post else {
            XCTFail("post should be decoded")
            return
        }
        switch lazyLoadedPost.modelProvider.getState() {
        case .notLoaded(let id):
            XCTAssertEqual(id, "postId")
        case .loaded:
            XCTFail("Should be not loaded")
        }
    }
    
    func testListCommentHasEagerLoadedPost() async throws {
        let post1 = LazyParentPost4V2(id: "postId1", title: "title1")
        _ = try await saveAsync(post1)
        let comment1 = LazyChildComment4V2(id: "id1", content: "content", post: post1)
        _ = try await saveAsync(comment1)
        let post2 = LazyParentPost4V2(id: "postId2", title: "title2")
        _ = try await saveAsync(post2)
        let comment2 = LazyChildComment4V2(id: "id2", content: "content", post: post2)
        _ = try await saveAsync(comment2)
        
        let comments = try await queryAsync(LazyChildComment4V2.self,
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
        guard let post1 = comment1.post else {
            XCTFail("missing post on comment1")
            return
        }
        guard let post2 = comment2.post else {
            XCTFail("missing post on comment2")
            return
        }
        
        switch post1.modelProvider.getState() {
        case .notLoaded:
            XCTFail("Should be loaded")
        case .loaded(let post):
            XCTAssertEqual(post!.id, "postId1")
            XCTAssertEqual(post!.title, "title1")
        }
        switch post2.modelProvider.getState() {
        case .notLoaded:
            XCTFail("Should be loaded")
        case .loaded(let post):
            XCTAssertEqual(post!.id, "postId2")
            XCTAssertEqual(post!.title, "title2")
        }
    }
    
    func testListCommentHasLazyLoadedPost() async throws {
        let post1 = LazyParentPost4V2(id: "postId1", title: "title1")
        _ = try await saveAsync(post1)
        let comment1 = LazyChildComment4V2(id: "id1", content: "content", post: post1)
        _ = try await saveAsync(comment1)
        let post2 = LazyParentPost4V2(id: "postId2", title: "title2")
        _ = try await saveAsync(post2)
        let comment2 = LazyChildComment4V2(id: "id2", content: "content", post: post2)
        _ = try await saveAsync(comment2)
        
        let comments = try await queryAsync(LazyChildComment4V2.self,
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
        guard let post1 = comment1.post else {
            XCTFail("missing post on comment1")
            return
        }
        guard let post2 = comment2.post else {
            XCTFail("missing post on comment2")
            return
        }
        
        switch post1.modelProvider.getState() {
        case .notLoaded(let identifier):
            XCTAssertEqual(identifier, "postId1")
        case .loaded:
            XCTFail("Should be not loaded")
        }
        switch post2.modelProvider.getState() {
        case .notLoaded(let identifier):
            XCTAssertEqual(identifier, "postId2")
        case .loaded:
            XCTFail("Should be not loaded")
        }
    }
}

// MARK: - Models

public struct LazyParentPost4V2: Model {
    public let id: String
    public var title: String
    public var comments: List<LazyChildComment4V2>?
    public var createdAt: Temporal.DateTime?
    public var updatedAt: Temporal.DateTime?
    
    public init(id: String = UUID().uuidString,
                title: String,
                comments: List<LazyChildComment4V2>? = []) {
        self.init(id: id,
                  title: title,
                  comments: comments,
                  createdAt: nil,
                  updatedAt: nil)
    }
    internal init(id: String = UUID().uuidString,
                  title: String,
                  comments: List<LazyChildComment4V2>? = [],
                  createdAt: Temporal.DateTime? = nil,
                  updatedAt: Temporal.DateTime? = nil) {
        self.id = id
        self.title = title
        self.comments = comments
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
extension LazyParentPost4V2 {
    // MARK: - CodingKeys
    public enum CodingKeys: String, ModelKey {
        case id
        case title
        case comments
        case createdAt
        case updatedAt
    }
    
    public static let keys = CodingKeys.self
    //  MARK: - ModelSchema
    
    public static let schema = defineSchema { model in
        let post4V2 = Post4V2.keys
        
        model.authRules = [
            rule(allow: .public, operations: [.create, .update, .delete, .read])
        ]
        
        model.pluralName = "Post4V2s"
        
        model.fields(
            .id(),
            .field(post4V2.title, is: .required, ofType: .string),
            .hasMany(post4V2.comments, is: .optional, ofType: LazyChildComment4V2.self, associatedWith: LazyChildComment4V2.keys.post),
            .field(post4V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
            .field(post4V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
        )
    }
}

public struct LazyChildComment4V2: Model {
    public let id: String
    public var content: String
    public var post: LazyModel<LazyParentPost4V2>?
    public var createdAt: Temporal.DateTime?
    public var updatedAt: Temporal.DateTime?
    
    public init(id: String = UUID().uuidString,
                content: String,
                post: LazyParentPost4V2? = nil) {
        self.init(id: id,
                  content: content,
                  post: post,
                  createdAt: nil,
                  updatedAt: nil)
    }
    internal init(id: String = UUID().uuidString,
                  content: String,
                  post: LazyParentPost4V2? = nil,
                  createdAt: Temporal.DateTime? = nil,
                  updatedAt: Temporal.DateTime? = nil) {
        self.id = id
        self.content = content
        self.post = LazyModel(element: post)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension LazyChildComment4V2 {
    // MARK: - CodingKeys
    public enum CodingKeys: String, ModelKey {
        case id
        case content
        case post
        case createdAt
        case updatedAt
    }
    
    public static let keys = CodingKeys.self
    //  MARK: - ModelSchema
    
    public static let schema = defineSchema { model in
        let comment4V2 = Comment4V2.keys
        
        model.authRules = [
            rule(allow: .public, operations: [.create, .update, .delete, .read])
        ]
        
        model.pluralName = "Comment4V2s"
        
        model.attributes(
            .index(fields: ["postID", "content"], name: "byPost4")
        )
        
        model.fields(
            .id(),
            .field(comment4V2.content, is: .required, ofType: .string),
            .belongsTo(comment4V2.post, is: .optional, ofType: LazyParentPost4V2.self, targetName: "postID"),
            .field(comment4V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
            .field(comment4V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
        )
    }
}
