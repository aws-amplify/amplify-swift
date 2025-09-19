//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Post41: Model {
  public let id: String
  public var title: String
  public var content: String
  var _author: LazyReference<Person41>
  public var author: Person41?   {
      get async throws {
        try await _author.get()
      }
    }
  var _editor: LazyReference<Person41>
  public var editor: Person41?   {
      get async throws {
        try await _editor.get()
      }
    }
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(
    id: String = UUID().uuidString,
    title: String,
    content: String,
    author: Person41? = nil,
    editor: Person41? = nil
  ) {
    self.init(
      id: id,
      title: title,
      content: content,
      author: author,
      editor: editor,
      createdAt: nil,
      updatedAt: nil
    )
  }
  init(
    id: String = UUID().uuidString,
    title: String,
    content: String,
    author: Person41? = nil,
    editor: Person41? = nil,
    createdAt: Temporal.DateTime? = nil,
    updatedAt: Temporal.DateTime? = nil
  ) {
      self.id = id
      self.title = title
      self.content = content
      self._author = LazyReference(author)
      self._editor = LazyReference(editor)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setAuthor(_ author: Person41? = nil) {
    _author = LazyReference(author)
  }
  public mutating func setEditor(_ editor: Person41? = nil) {
    _editor = LazyReference(editor)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      self.id = try values.decode(String.self, forKey: .id)
      self.title = try values.decode(String.self, forKey: .title)
      self.content = try values.decode(String.self, forKey: .content)
      self._author = try values.decodeIfPresent(LazyReference<Person41>.self, forKey: .author) ?? LazyReference(identifiers: nil)
      self._editor = try values.decodeIfPresent(LazyReference<Person41>.self, forKey: .editor) ?? LazyReference(identifiers: nil)
      self.createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      self.updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(title, forKey: .title)
      try container.encode(content, forKey: .content)
      try container.encode(_author, forKey: .author)
      try container.encode(_editor, forKey: .editor)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}
