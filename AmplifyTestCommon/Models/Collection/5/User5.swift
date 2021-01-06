//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct User5: Model {
  public let id: String
  public var username: String
  public var posts: List<PostEditor5>?

  public init(id: String = UUID().uuidString,
      username: String,
      posts: List<PostEditor5>? = []) {
      self.id = id
      self.username = username
      self.posts = posts
  }
}
