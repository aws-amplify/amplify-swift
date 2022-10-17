// swiftlint:disable all
import Amplify
import Foundation

public struct Comment7: Model {
  public let commentId: String
  public let content: String
  public var post: Post7?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(commentId: String,
      content: String,
      post: Post7? = nil) {
    self.init(commentId: commentId,
      content: content,
      post: post,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(commentId: String,
      content: String,
      post: Post7? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.commentId = commentId
      self.content = content
      self.post = post
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}