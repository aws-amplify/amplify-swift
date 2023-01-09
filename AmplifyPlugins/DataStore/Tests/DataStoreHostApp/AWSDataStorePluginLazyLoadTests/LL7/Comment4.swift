// swiftlint:disable all
import Amplify
import Foundation

public struct Comment4: Model {
  public let commentId: String
  public let content: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var post4CommentsPostId: String?
  public var post4CommentsTitle: String?
  
  public init(commentId: String,
      content: String,
      post4CommentsPostId: String? = nil,
      post4CommentsTitle: String? = nil) {
    self.init(commentId: commentId,
      content: content,
      createdAt: nil,
      updatedAt: nil,
      post4CommentsPostId: post4CommentsPostId,
      post4CommentsTitle: post4CommentsTitle)
  }
  internal init(commentId: String,
      content: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil,
      post4CommentsPostId: String? = nil,
      post4CommentsTitle: String? = nil) {
      self.commentId = commentId
      self.content = content
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.post4CommentsPostId = post4CommentsPostId
      self.post4CommentsTitle = post4CommentsTitle
  }
}