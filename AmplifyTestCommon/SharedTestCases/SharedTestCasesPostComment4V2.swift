//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/*
 type Post4V2 @model @auth(rules: [{allow: public}]) {
   id: ID!
   title: String!
   comments: [Comment4V2] @hasMany(indexName: "byPost4", fields: ["id"])
 }

 type Comment4V2 @model @auth(rules: [{allow: public}]) {
   id: ID!
   postID: ID! @index(name: "byPost4", sortKeyFields: ["content"])
   content: String!
   post: Post4V2 @belongsTo(fields: ["postID"])
 }
 */

protocol SharedTestCasesPostComment4V2 {
    
    func testSaveCommentThenQueryComment() async throws
    
    func testSavePostThenQueryPost() async throws
    
    func testSaveMultipleThenQueryComments() async throws
    
    func testSaveMultipleThenQueryPosts() async throws
    
    func testSaveCommentWithPostThenQueryCommentAndAccessPost() async throws
    
    func testSaveCommentWithPostThenQueryPostAndAccessComments() async throws
    
    func testSaveMultipleCommentWithPostThenQueryCommentsAndAccessPost() async throws
    
    func testSaveMultipleCommentWithPostThenQueryPostAndAccessComments() async throws
}

// MARK: - Models with LazyModel

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
        
        model.pluralName = "LazyParentPost4V2s"
        
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
    internal var _post: LazyReference<LazyParentPost4V2>
    public var post: LazyParentPost4V2? {
        get async throws {
            try await _post.get()
        }
    }
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
        self._post = LazyReference(post)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public mutating func setPost(_ post: LazyParentPost4V2) {
        self._post = LazyReference(post)
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        content = try values.decode(String.self, forKey: .content)
        createdAt = try values.decode(Temporal.DateTime?.self, forKey: .createdAt)
        updatedAt = try values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
        _post = try values.decode(LazyReference<LazyParentPost4V2>.self, forKey: .post)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(_post, forKey: .post)
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
        
        model.pluralName = "LazyChildComment4V2s"
        
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

// MARK: - Models without LazyModel

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

    model.pluralName = "ParentPost4V2s"

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

    model.pluralName = "ChildComment4V2s"

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
