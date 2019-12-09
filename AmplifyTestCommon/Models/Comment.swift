//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Comment: Model {
  public let id: String
  public var content: String
  public var createdAt: Date
  public var post: Post

  public init(id: String = UUID().uuidString,
      content: String,
      createdAt: Date,
      post: Post) {
      self.id = id
      self.content = content
      self.createdAt = createdAt
      self.post = post
  }
}
