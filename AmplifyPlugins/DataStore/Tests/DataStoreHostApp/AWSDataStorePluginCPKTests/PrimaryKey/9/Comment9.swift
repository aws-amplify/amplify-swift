// swiftlint:disable all
import Amplify
import Foundation

public struct Comment9: Model {
  public let commentId: String
  public let postId: String
  public var content: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(commentId: String,
      postId: String,
      content: String? = nil) {
    self.init(commentId: commentId,
      postId: postId,
      content: content,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(commentId: String,
      postId: String,
      content: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.commentId = commentId
      self.postId = postId
      self.content = content
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}