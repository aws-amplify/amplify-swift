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

final class StorageEngineTestsPostComment4V2Tests: StorageEngineTestsBase {

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

    func testQueryComment() async throws {
        let comment = ChildComment4V2(content: "content")
        _ = try await saveAsync(comment)
        
        guard (try await queryAsync(ChildComment4V2.self,
                                    byIdentifier: comment.id)) != nil else {
            XCTFail("Failed to query saved comment")
            return
        }
    }
    
    func testQueryPost() async throws {
        let post = ParentPost4V2(title: "title")
        _ = try await saveAsync(post)
        
        guard (try await queryAsync(ParentPost4V2.self,
                                    byIdentifier: post.id)) != nil else {
            XCTFail("Failed to query saved post")
            return
        }
    }
    
    func testQueryListComments() async throws {
        _ = try await saveAsync(ChildComment4V2(content: "content"))
        _ = try await saveAsync(ChildComment4V2(content: "content"))
        
        let comments = try await queryAsync(ChildComment4V2.self)
        XCTAssertEqual(comments.count, 2)
    }
    
    func testQueryListPosts() async throws {
        _ = try await saveAsync(ParentPost4V2(title: "title"))
        _ = try await saveAsync(ParentPost4V2(title: "title"))
        
        let comments = try await queryAsync(ParentPost4V2.self)
        XCTAssertEqual(comments.count, 2)
    }
    
    func testPostHasLazyLoadedComments() async throws {
        let post = ParentPost4V2(title: "title")
        _ = try await saveAsync(post)
        let comment = ChildComment4V2(content: "content", post: post)
        _ = try await saveAsync(comment)
        
        guard let queriedPost = try await queryAsync(ParentPost4V2.self,
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
            print("loaded comments \(comments)")
            XCTFail("Should not be loaded")
        }
    }
    
    func testCommentHasEagerLoadedPost() async throws {
        let post = ParentPost4V2(title: "title")
        _ = try await saveAsync(post)
        let comment = ChildComment4V2(content: "content", post: post)
        _ = try await saveAsync(comment)
        
        guard let queriedComment = try await queryAsync(ChildComment4V2.self,
                                                     byIdentifier: comment.id) else {
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
    
    func testCommentHasEagerLoadedPost_InsertUpdateSelect() async throws {
        let post = ParentPost4V2(title: "title")
        _ = try await saveAsync(post)
        var comment = ChildComment4V2(content: "content", post: post)
        
        // Insert
        let insertStatement = InsertStatement(model: comment, modelSchema: ChildComment4V2.schema)
        print(insertStatement.stringValue)
        print(insertStatement.variables)
        _ = try connection.prepare(insertStatement.stringValue).run(insertStatement.variables)
        
        // Update
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
    
    func testComentHasEagerLoadedPost() async throws {
        let post1 = try await saveAsync(ParentPost4V2(id: "postId1", title: "title1"))
        _ = try await saveAsync(ChildComment4V2(id: "id1", content: "content", post: post1))
        let post2 = try await saveAsync(ParentPost4V2(id: "postId2", title: "title2"))
        _ = try await saveAsync(ChildComment4V2(id: "id2", content: "content", post: post2))
        let comments = try await queryAsync(ChildComment4V2.self)
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
    
}

// MARK: - Models

public struct ParentPost4V2: Model {
  public let id: String
  public var title: String
  public var comments: List<ChildComment4V2>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      title: String,
      comments: List<ChildComment4V2>? = []) {
    self.init(id: id,
      title: title,
      comments: comments,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      title: String,
      comments: List<ChildComment4V2>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.title = title
      self.comments = comments
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
extension ParentPost4V2 {
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
      .hasMany(post4V2.comments, is: .optional, ofType: ChildComment4V2.self, associatedWith: ChildComment4V2.keys.post),
      .field(post4V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post4V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

public struct ChildComment4V2: Model {
  public let id: String
  public var content: String
  public var post: ParentPost4V2?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      content: String,
      post: ParentPost4V2? = nil) {
    self.init(id: id,
      content: content,
      post: post,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      content: String,
      post: ParentPost4V2? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.content = content
      self.post = post
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}

extension ChildComment4V2 {
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
      .belongsTo(comment4V2.post, is: .optional, ofType: ParentPost4V2.self, targetName: "postID"),
      .field(comment4V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment4V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
