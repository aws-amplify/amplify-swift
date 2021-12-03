//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct User5V2: Model {
  public let id: String
  public var username: String
  public var posts: List<PostEditor5V2>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      username: String,
      posts: List<PostEditor5V2>? = []) {
    self.init(id: id,
      username: username,
      posts: posts,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      username: String,
      posts: List<PostEditor5V2>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.username = username
      self.posts = posts
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
