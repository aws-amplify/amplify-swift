//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct PostWithCompositeKey: Model {
  public let id: String
  public let title: String
  public var comments: List<CommentWithCompositeKey>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      title: String,
      comments: List<CommentWithCompositeKey>? = []) {
    self.init(id: id,
      title: title,
      comments: comments,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      title: String,
      comments: List<CommentWithCompositeKey>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.title = title
      self.comments = comments
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
