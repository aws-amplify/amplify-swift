// swiftlint:disable all
import Amplify
import Foundation

public struct Comment4: Model {
  public let id: String
  public var content: String
  public var post: Post4?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      content: String,
      post: Post4? = nil) {
    self.init(id: id,
      content: content,
      post: post,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      content: String,
      post: Post4? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.content = content
      self.post = post
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}