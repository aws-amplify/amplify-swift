//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct TodoExplicitOwnerField: Model {
  public let id: String
  public var content: String
  public var owner: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      content: String,
      owner: String? = nil) {
    self.init(id: id,
      content: content,
      owner: owner,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      content: String,
      owner: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.content = content
      self.owner = owner
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
