//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct PostWithTagsCompositeKey: Model {
  public let postId: String
  public let title: String
  public var tags: List<PostTagsWithCompositeKey>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(postId: String,
      title: String,
      tags: List<PostTagsWithCompositeKey>? = []) {
    self.init(postId: postId,
      title: title,
      tags: tags,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(postId: String,
      title: String,
      tags: List<PostTagsWithCompositeKey>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.postId = postId
      self.title = title
      self.tags = tags
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
