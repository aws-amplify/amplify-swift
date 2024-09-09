//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Customer4: Model {
  public let id: String
  public var name: String?
  var _activeCart: LazyReference<Cart4>
  public var activeCart: Cart4?   {
      get async throws {
        try await _activeCart.get()
      }
    }
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(
    id: String = UUID().uuidString,
    name: String? = nil,
    activeCart: Cart4? = nil
  ) {
    self.init(
      id: id,
      name: name,
      activeCart: activeCart,
      createdAt: nil,
      updatedAt: nil
    )
  }
  init(
    id: String = UUID().uuidString,
    name: String? = nil,
    activeCart: Cart4? = nil,
    createdAt: Temporal.DateTime? = nil,
    updatedAt: Temporal.DateTime? = nil
  ) {
      self.id = id
      self.name = name
      self._activeCart = LazyReference(activeCart)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setActiveCart(_ activeCart: Cart4? = nil) {
    _activeCart = LazyReference(activeCart)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      self.id = try values.decode(String.self, forKey: .id)
      self.name = try? values.decode(String?.self, forKey: .name)
      self._activeCart = try values.decodeIfPresent(LazyReference<Cart4>.self, forKey: .activeCart) ?? LazyReference(identifiers: nil)
      self.createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      self.updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(name, forKey: .name)
      try container.encode(_activeCart, forKey: .activeCart)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}
