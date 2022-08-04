//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct CommentWithCompositeKeyUnidirectional: Model {
  public let id: String
  public let content: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var postWithCompositeKeyUnidirectionalCommentsId: String?
  public var postWithCompositeKeyUnidirectionalCommentsTitle: String?

  public init(id: String = UUID().uuidString,
      content: String,
      post21CommentsId: String? = nil,
      post21CommentsTitle: String? = nil) {
    self.init(id: id,
      content: content,
      createdAt: nil,
      updatedAt: nil,
      postWithCompositeKeyUnidirectionalCommentsId: post21CommentsId,
      postWithCompositeKeyUnidirectionalCommentsTitle: post21CommentsTitle)
  }
  internal init(id: String = UUID().uuidString,
                content: String,
                createdAt: Temporal.DateTime? = nil,
                updatedAt: Temporal.DateTime? = nil,
                postWithCompositeKeyUnidirectionalCommentsId: String? = nil,
                postWithCompositeKeyUnidirectionalCommentsTitle: String? = nil) {
      self.id = id
      self.content = content
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.postWithCompositeKeyUnidirectionalCommentsId = postWithCompositeKeyUnidirectionalCommentsId
      self.postWithCompositeKeyUnidirectionalCommentsTitle = postWithCompositeKeyUnidirectionalCommentsTitle
  }
}
