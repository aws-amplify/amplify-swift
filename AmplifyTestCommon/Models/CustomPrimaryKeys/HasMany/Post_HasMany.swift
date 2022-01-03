//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Post_HasMany_1toM_Case1_v1: Model {
  public let id: String
  public var postID: String
  public var title: String
  public var comments: List<Comment_HasMany_1toM_Case1_v1>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      postID: String,
      title: String,
      comments: List<Comment_HasMany_1toM_Case1_v1>? = []) {
    self.init(id: id,
      postID: postID,
      title: title,
      comments: comments,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      postID: String,
      title: String,
      comments: List<Comment_HasMany_1toM_Case1_v1>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.postID = postID
      self.title = title
      self.comments = comments
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}

public struct Post_HasMany_1toM_Case2_v1: Model {
  public let id: String
  public var title: String
  public var comments: List<Comment_HasMany_1toM_Case2_v1>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      title: String,
      comments: List<Comment_HasMany_1toM_Case2_v1>? = []) {
    self.init(id: id,
      title: title,
      comments: comments,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      title: String,
      comments: List<Comment_HasMany_1toM_Case2_v1>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.title = title
      self.comments = comments
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}

public struct Post_HasMany_1toM_Case3_v1: Model {
  public let id: String
  public var postID: String
  public var title: String
  public var comments: List<Comment_HasMany_1toM_Case3_v1>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      postID: String,
      title: String,
      comments: List<Comment_HasMany_1toM_Case3_v1>? = []) {
    self.init(id: id,
      postID: postID,
      title: title,
      comments: comments,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      postID: String,
      title: String,
      comments: List<Comment_HasMany_1toM_Case3_v1>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.postID = postID
      self.title = title
      self.comments = comments
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}

