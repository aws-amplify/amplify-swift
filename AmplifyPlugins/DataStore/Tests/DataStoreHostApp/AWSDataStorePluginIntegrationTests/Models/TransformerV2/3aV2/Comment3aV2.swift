//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Comment3aV2: Model {
  public let id: String
  public var content: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var post3aV2CommentsId: String?

  public init(id: String = UUID().uuidString,
      content: String,
      post3aV2CommentsId: String? = nil) {
    self.init(id: id,
      content: content,
      createdAt: nil,
      updatedAt: nil,
      post3aV2CommentsId: post3aV2CommentsId)
  }
  internal init(id: String = UUID().uuidString,
      content: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil,
      post3aV2CommentsId: String? = nil) {
      self.id = id
      self.content = content
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.post3aV2CommentsId = post3aV2CommentsId
  }
}
