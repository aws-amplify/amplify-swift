//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Comment4: Model {
  public let id: String
  public var content: String
  public var post: Post4?

  public init(id: String = UUID().uuidString,
      content: String,
      post: Post4? = nil) {
      self.id = id
      self.content = content
      self.post = post
  }
}
