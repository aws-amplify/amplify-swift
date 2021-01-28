//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct M2MUser: Model {
  public let id: String
  public var username: String
  public var posts: List<M2MPostEditor>?

  public init(id: String = UUID().uuidString,
      username: String,
      posts: List<M2MPostEditor>? = []) {
      self.id = id
      self.username = username
      self.posts = posts
  }
}
