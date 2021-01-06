//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Blog6: Model {
  public let id: String
  public var name: String
  public var posts: List<Post6>?

  public init(id: String = UUID().uuidString,
      name: String,
      posts: List<Post6>? = []) {
      self.id = id
      self.name = name
      self.posts = posts
  }
}
