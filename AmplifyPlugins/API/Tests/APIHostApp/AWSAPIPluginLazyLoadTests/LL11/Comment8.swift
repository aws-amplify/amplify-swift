// swiftlint:disable all
import Amplify
import Foundation

public struct Comment8: Model {
  public let commentId: String
  public let content: String
  public var postId: String?
  public var postTitle: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(commentId: String,
      content: String,
      postId: String? = nil,
      postTitle: String? = nil) {
    self.init(commentId: commentId,
      content: content,
      postId: postId,
      postTitle: postTitle,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(commentId: String,
      content: String,
      postId: String? = nil,
      postTitle: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.commentId = commentId
      self.content = content
      self.postId = postId
      self.postTitle = postTitle
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}