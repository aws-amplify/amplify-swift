// swiftlint:disable all
import Amplify
import Foundation

public struct Person41: Model {
  public let id: String
  public var name: String?
  public var editedPosts: List<Post41>?
  public var authoredPosts: List<Post41>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      name: String? = nil,
      editedPosts: List<Post41>? = [],
      authoredPosts: List<Post41>? = []) {
    self.init(id: id,
      name: name,
      editedPosts: editedPosts,
      authoredPosts: authoredPosts,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String? = nil,
      editedPosts: List<Post41>? = [],
      authoredPosts: List<Post41>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.editedPosts = editedPosts
      self.authoredPosts = authoredPosts
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}