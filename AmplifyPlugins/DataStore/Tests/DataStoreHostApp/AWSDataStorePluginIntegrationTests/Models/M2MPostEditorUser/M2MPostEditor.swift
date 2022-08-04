//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct M2MPostEditor: Model {
  public let id: String
  public var post: M2MPost
  public var editor: M2MUser

  public init(id: String = UUID().uuidString,
      post: M2MPost,
      editor: M2MUser) {
      self.id = id
      self.post = post
      self.editor = editor
  }
}
