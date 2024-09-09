//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Post14: Model {
  public let id: String
  public var title: String
  public var rating: Int
  public var status: PostStatus
  public var comments: List<Comment14>?
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
    title: String,
    rating: Int,
    status: PostStatus,
    comments: List<Comment14>? = [],
    author: User14
  ) {
    self.init(
      id: id,
      title: title,
      rating: rating,
      status: status,
      comments: comments,
      author: author,
      createdAt: nil,
      updatedAt: nil
    )
  }
  init(
    id: String = UUID().uuidString,
    title: String,
    rating: Int,
    status: PostStatus,
    comments: List<Comment14>? = [],
    author: User14,
    createdAt: Temporal.DateTime? = nil,
    updatedAt: Temporal.DateTime? = nil
  ) {
      self.id = id
      self.title = title
      self.rating = rating
      self.status = status
      self.comments = comments
      self._author = LazyReference(author)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setAuthor(_ author: User14) {
    _author = LazyReference(author)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      self.id = try values.decode(String.self, forKey: .id)
      self.title = try values.decode(String.self, forKey: .title)
      self.rating = try values.decode(Int.self, forKey: .rating)
      self.status = try values.decode(PostStatus.self, forKey: .status)
      self.comments = try values.decodeIfPresent(List<Comment14>?.self, forKey: .comments) ?? .init()
      self._author = try values.decodeIfPresent(LazyReference<User14>.self, forKey: .author) ?? LazyReference(identifiers: nil)
      self.createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      self.updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(title, forKey: .title)
      try container.encode(rating, forKey: .rating)
      try container.encode(status, forKey: .status)
      try container.encode(comments, forKey: .comments)
      try container.encode(_author, forKey: .author)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}
