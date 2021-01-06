//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Post6: Model {
  public let id: String
  public var title: String
  public var blog: Blog6?
  public var comments: List<Comment6>?

  public init(id: String = UUID().uuidString,
      title: String,
      blog: Blog6? = nil,
      comments: List<Comment6>? = []) {
      self.id = id
      self.title = title
      self.blog = blog
      self.comments = comments
  }
}
