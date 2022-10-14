// swiftlint:disable all
import Amplify
import Foundation

public struct CommentWithCompositeKeyAndIndex: Model {
  public let id: String
  public let content: String
  public var post: PostWithCompositeKeyAndIndex?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      content: String,
      post: PostWithCompositeKeyAndIndex? = nil) {
    self.init(id: id,
      content: content,
      post: post,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      content: String,
      post: PostWithCompositeKeyAndIndex? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.content = content
      self.post = post
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}