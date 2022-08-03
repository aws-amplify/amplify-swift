// swiftlint:disable all
import Amplify
import Foundation

public struct Comment6: Model {
  public let id: String
  public var post: Post6?
  public var content: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      post: Post6? = nil,
      content: String) {
    self.init(id: id,
      post: post,
      content: content,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      post: Post6? = nil,
      content: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.post = post
      self.content = content
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}