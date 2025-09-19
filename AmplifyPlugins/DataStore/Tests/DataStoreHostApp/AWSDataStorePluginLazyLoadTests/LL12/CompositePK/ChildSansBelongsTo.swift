//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct ChildSansBelongsTo: Model {
  public let childId: String
  public let content: String
  public var compositePKParentChildrenSansBelongsToCustomId: String
  public var compositePKParentChildrenSansBelongsToContent: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(
      childId: String,
      content: String,
      compositePKParentChildrenSansBelongsToCustomId: String,
      compositePKParentChildrenSansBelongsToContent: String? = nil
  ) {
    self.init(
        childId: childId,
        content: content,
        compositePKParentChildrenSansBelongsToCustomId: compositePKParentChildrenSansBelongsToCustomId,
        compositePKParentChildrenSansBelongsToContent: compositePKParentChildrenSansBelongsToContent,
        createdAt: nil,
        updatedAt: nil
    )
  }
  init(
      childId: String,
      content: String,
      compositePKParentChildrenSansBelongsToCustomId: String,
      compositePKParentChildrenSansBelongsToContent: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil
  ) {
      self.childId = childId
      self.content = content
      self.compositePKParentChildrenSansBelongsToCustomId = compositePKParentChildrenSansBelongsToCustomId
      self.compositePKParentChildrenSansBelongsToContent = compositePKParentChildrenSansBelongsToContent
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      self.childId = try values.decode(String.self, forKey: .childId)
      self.content = try values.decode(String.self, forKey: .content)
      self.compositePKParentChildrenSansBelongsToCustomId = try values.decode(String.self, forKey: .compositePKParentChildrenSansBelongsToCustomId)
      self.compositePKParentChildrenSansBelongsToContent = try values.decode(String?.self, forKey: .compositePKParentChildrenSansBelongsToContent)
      self.createdAt = try values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      self.updatedAt = try values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(childId, forKey: .childId)
      try container.encode(content, forKey: .content)
      try container.encode(compositePKParentChildrenSansBelongsToCustomId, forKey: .compositePKParentChildrenSansBelongsToCustomId)
      try container.encode(compositePKParentChildrenSansBelongsToContent, forKey: .compositePKParentChildrenSansBelongsToContent)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}
