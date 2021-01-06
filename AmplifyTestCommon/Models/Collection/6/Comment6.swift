//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Comment6: Model {
  public let id: String
  public var post: Post6?
  public var content: String

  public init(id: String = UUID().uuidString,
      post: Post6? = nil,
      content: String) {
      self.id = id
      self.post = post
      self.content = content
  }
}
