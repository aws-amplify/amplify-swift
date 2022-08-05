//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Comment3: Model {
  public let id: String
  public var postID: String
  public var content: String

  public init(id: String = UUID().uuidString,
      postID: String,
      content: String) {
      self.id = id
      self.postID = postID
      self.content = content
  }
}
