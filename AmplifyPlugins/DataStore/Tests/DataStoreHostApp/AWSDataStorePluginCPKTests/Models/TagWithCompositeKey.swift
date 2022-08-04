//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct TagWithCompositeKey: Model {
  public let id: String
  public let name: String
  public var posts: List<PostTagsWithCompositeKey>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      name: String,
      posts: List<PostTagsWithCompositeKey>? = []) {
    self.init(id: id,
      name: name,
      posts: posts,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String,
      posts: List<PostTagsWithCompositeKey>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.posts = posts
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
