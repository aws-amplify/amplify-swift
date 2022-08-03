// swiftlint:disable all
import Amplify
import Foundation

public struct PostEditor5: Model {
  public let id: String
  public var post: Post5
  public var editor: User5
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      post: Post5,
      editor: User5) {
    self.init(id: id,
      post: post,
      editor: editor,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      post: Post5,
      editor: User5,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.post = post
      self.editor = editor
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}