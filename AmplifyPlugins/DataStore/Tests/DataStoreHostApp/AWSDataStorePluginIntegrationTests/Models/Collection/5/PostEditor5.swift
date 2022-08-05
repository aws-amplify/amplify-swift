//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct PostEditor5: Model {
  public let id: String
  public var post: Post5
  public var editor: User5

  public init(id: String = UUID().uuidString,
      post: Post5,
      editor: User5) {
      self.id = id
      self.post = post
      self.editor = editor
  }
}
