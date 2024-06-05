// swiftlint:disable all
import Amplify
import Foundation

public struct Post41: Model {
  public let id: String
  public var title: String
  public var content: String
  internal var _author: LazyReference<Person41>
  public var author: Person41?   {
      get async throws { 
        try await _author.get()
      } 
    }
  internal var _editor: LazyReference<Person41>
  public var editor: Person41?   {
      get async throws { 
        try await _editor.get()
      } 
    }
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      title: String,
      content: String,
      author: Person41? = nil,
      editor: Person41? = nil) {
    self.init(id: id,
      title: title,
      content: content,
      author: author,
      editor: editor,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      title: String,
      content: String,
      author: Person41? = nil,
      editor: Person41? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.title = title
      self.content = content
      self._author = LazyReference(author)
      self._editor = LazyReference(editor)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setAuthor(_ author: Person41? = nil) {
    self._author = LazyReference(author)
  }
  public mutating func setEditor(_ editor: Person41? = nil) {
    self._editor = LazyReference(editor)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      title = try values.decode(String.self, forKey: .title)
      content = try values.decode(String.self, forKey: .content)
      _author = try values.decodeIfPresent(LazyReference<Person41>.self, forKey: .author) ?? LazyReference(identifiers: nil)
      _editor = try values.decodeIfPresent(LazyReference<Person41>.self, forKey: .editor) ?? LazyReference(identifiers: nil)
      createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
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