//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct User14: Model {
  public let id: String
  public var username: String
  public var posts: List<Post14>?
  public var comments: List<Comment14>?
  var _settings: LazyReference<UserSettings14>
  public var settings: UserSettings14?   {
      get async throws {
        try await _settings.get()
      }
    }
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var user14SettingsId: String?

  public init(
    id: String = UUID().uuidString,
    username: String,
    posts: List<Post14>? = [],
    comments: List<Comment14>? = [],
    settings: UserSettings14? = nil,
    user14SettingsId: String? = nil
  ) {
    self.init(
      id: id,
      username: username,
      posts: posts,
      comments: comments,
      settings: settings,
      createdAt: nil,
      updatedAt: nil,
      user14SettingsId: user14SettingsId
    )
  }
  init(
    id: String = UUID().uuidString,
    username: String,
    posts: List<Post14>? = [],
    comments: List<Comment14>? = [],
    settings: UserSettings14? = nil,
    createdAt: Temporal.DateTime? = nil,
    updatedAt: Temporal.DateTime? = nil,
    user14SettingsId: String? = nil
  ) {
      self.id = id
      self.username = username
      self.posts = posts
      self.comments = comments
      self._settings = LazyReference(settings)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.user14SettingsId = user14SettingsId
  }
  public mutating func setSettings(_ settings: UserSettings14? = nil) {
    _settings = LazyReference(settings)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      self.id = try values.decode(String.self, forKey: .id)
      self.username = try values.decode(String.self, forKey: .username)
      self.posts = try values.decodeIfPresent(List<Post14>?.self, forKey: .posts) ?? .init()
      self.comments = try values.decodeIfPresent(List<Comment14>?.self, forKey: .comments) ?? .init()
      self._settings = try values.decodeIfPresent(LazyReference<UserSettings14>.self, forKey: .settings) ?? LazyReference(identifiers: nil)
      self.createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      self.updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
      self.user14SettingsId = try? values.decode(String?.self, forKey: .user14SettingsId)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(username, forKey: .username)
      try container.encode(posts, forKey: .posts)
      try container.encode(comments, forKey: .comments)
      try container.encode(_settings, forKey: .settings)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
      try container.encode(user14SettingsId, forKey: .user14SettingsId)
  }
}
