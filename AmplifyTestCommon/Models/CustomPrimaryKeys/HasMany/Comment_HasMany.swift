//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Comment_HasMany_1toM_Case1_v1: Model {
  public let id: String
  public var postID: String
  public var content: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      postID: String,
      content: String) {
    self.init(id: id,
      postID: postID,
      content: content,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      postID: String,
      content: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.postID = postID
      self.content = content
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}

public struct Comment_HasMany_1toM_Case2_v1: Model {
  public let id: String
  public var commentID: String
  public var postID: String
  public var content: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      commentID: String,
      postID: String,
      content: String) {
    self.init(id: id,
      commentID: commentID,
      postID: postID,
      content: content,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      commentID: String,
      postID: String,
      content: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.commentID = commentID
      self.postID = postID
      self.content = content
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}

public struct Comment_HasMany_1toM_Case3_v1: Model {
  public let id: String
  public var commentID: String
  public var postID: String
  public var content: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      commentID: String,
      postID: String,
      content: String) {
    self.init(id: id,
      commentID: commentID,
      postID: postID,
      content: content,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      commentID: String,
      postID: String,
      content: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.commentID = commentID
      self.postID = postID
      self.content = content
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}

