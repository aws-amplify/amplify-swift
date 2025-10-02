//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Comment14: Model {
  public let id: String
  public var content: String?
  var _post: LazyReference<Post14>
  public var post: Post14?   {
      get async throws {
        try await _post.get()
      }
    }
  var _author: LazyReference<User14>
  public var author: User14   {
      get async throws {
        try await _author.require()
      }
    }
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(
    id: String = UUID().uuidString,
    content: String? = nil,
    post: Post14? = nil,
    author: User14
  ) {
    self.init(
      id: id,
      content: content,
      post: post,
      author: author,
      createdAt: nil,
      updatedAt: nil
    )
  }
  init(
    id: String = UUID().uuidString,
    content: String? = nil,
    post: Post14? = nil,
    author: User14,
    createdAt: Temporal.DateTime? = nil,
    updatedAt: Temporal.DateTime? = nil
  ) {
      self.id = id
      self.content = content
      self._post = LazyReference(post)
      self._author = LazyReference(author)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setPost(_ post: Post14? = nil) {
    _post = LazyReference(post)
  }
  public mutating func setAuthor(_ author: User14) {
    _author = LazyReference(author)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      self.id = try values.decode(String.self, forKey: .id)
      self.content = try? values.decode(String?.self, forKey: .content)
      self._post = try values.decodeIfPresent(LazyReference<Post14>.self, forKey: .post) ?? LazyReference(identifiers: nil)
      self._author = try values.decodeIfPresent(LazyReference<User14>.self, forKey: .author) ?? LazyReference(identifiers: nil)
      self.createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      self.updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(content, forKey: .content)
      try container.encode(_post, forKey: .post)
      try container.encode(_author, forKey: .author)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}
