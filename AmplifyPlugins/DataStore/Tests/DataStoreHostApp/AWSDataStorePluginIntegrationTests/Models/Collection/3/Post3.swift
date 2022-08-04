//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Post3: Model {
  public let id: String
  public var title: String
  public var comments: List<Comment3>?

  public init(id: String = UUID().uuidString,
      title: String,
      comments: List<Comment3>? = []) {
      self.id = id
      self.title = title
      self.comments = comments
  }
}
