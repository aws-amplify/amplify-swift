//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct DefaultPKChild: Model {
  public let id: String
  public var content: String?
  var _parent: LazyReference<DefaultPKParent>
  public var parent: DefaultPKParent?   {
      get async throws {
        try await _parent.get()
      }
    }
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(
    id: String = UUID().uuidString,
    content: String? = nil,
    parent: DefaultPKParent? = nil
  ) {
    self.init(
      id: id,
      content: content,
      parent: parent,
      createdAt: nil,
      updatedAt: nil
    )
  }
  init(
    id: String = UUID().uuidString,
    content: String? = nil,
    parent: DefaultPKParent? = nil,
    createdAt: Temporal.DateTime? = nil,
    updatedAt: Temporal.DateTime? = nil
  ) {
      self.id = id
      self.content = content
      self._parent = LazyReference(parent)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setParent(_ parent: DefaultPKParent? = nil) {
    _parent = LazyReference(parent)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      self.id = try values.decode(String.self, forKey: .id)
      self.content = try? values.decode(String?.self, forKey: .content)
      self._parent = try values.decodeIfPresent(LazyReference<DefaultPKParent>.self, forKey: .parent) ?? LazyReference(identifiers: nil)
      self.createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      self.updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(content, forKey: .content)
      try container.encode(_parent, forKey: .parent)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}
