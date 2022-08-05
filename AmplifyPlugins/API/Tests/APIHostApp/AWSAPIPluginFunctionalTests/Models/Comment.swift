// swiftlint:disable all
import Amplify
import Foundation

public struct Comment: Model {
  public let id: String
  public var content: String
  public var createdAt: Temporal.DateTime
  public var post: Post?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      content: String,
      createdAt: Temporal.DateTime,
      post: Post? = nil) {
    self.init(id: id,
      content: content,
      createdAt: createdAt,
      post: post,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      content: String,
      createdAt: Temporal.DateTime,
      post: Post? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.content = content
      self.createdAt = createdAt
      self.post = post
      self.updatedAt = updatedAt
  }
}