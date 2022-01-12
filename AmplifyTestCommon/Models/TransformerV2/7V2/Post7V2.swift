//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Post7V2: Model {
  public let id: String
  public var title: String
  public var blog: Blog7V2?
  public var comments: List<Comment7V2>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      title: String,
      blog: Blog7V2? = nil,
      comments: List<Comment7V2>? = []) {
    self.init(id: id,
      title: title,
      blog: blog,
      comments: comments,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      title: String,
      blog: Blog7V2? = nil,
      comments: List<Comment7V2>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.title = title
      self.blog = blog
      self.comments = comments
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
