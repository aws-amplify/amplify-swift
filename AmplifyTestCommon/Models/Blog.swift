//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Blog: Model {
  public let id: String
  public var title: String
  public var createdAt: Temporal.DateTime
  public var posts: List<Post>?

  public init(id: String = UUID().uuidString,
      title: String,
      createdAt: Temporal.DateTime,
      posts: List<Post>? = []) {
      self.id = id
      self.title = title
      self.createdAt = createdAt
      self.posts = posts
  }
}
