//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct UserSettings14: Model {
  public let id: String
  public var language: String?
  var _user: LazyReference<User14>
  public var user: User14   {
      get async throws {
        try await _user.require()
      }
    }
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(
    id: String = UUID().uuidString,
    language: String? = nil,
    user: User14
  ) {
    self.init(
      id: id,
      language: language,
      user: user,
      createdAt: nil,
      updatedAt: nil
    )
  }
  init(
    id: String = UUID().uuidString,
    language: String? = nil,
    user: User14,
    createdAt: Temporal.DateTime? = nil,
    updatedAt: Temporal.DateTime? = nil
  ) {
      self.id = id
      self.language = language
      self._user = LazyReference(user)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setUser(_ user: User14) {
    _user = LazyReference(user)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      self.id = try values.decode(String.self, forKey: .id)
      self.language = try? values.decode(String?.self, forKey: .language)
      self._user = try values.decodeIfPresent(LazyReference<User14>.self, forKey: .user) ?? LazyReference(identifiers: nil)
      self.createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      self.updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(language, forKey: .language)
      try container.encode(_user, forKey: .user)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}
