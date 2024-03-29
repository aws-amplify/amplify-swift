// swiftlint:disable all
import Amplify
import Foundation

public struct Post9: Model {
  public let postId: String
  public var title: String?
  public var comments: List<Comment9>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(postId: String,
      title: String? = nil,
      comments: List<Comment9>? = []) {
    self.init(postId: postId,
      title: title,
      comments: comments,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(postId: String,
      title: String? = nil,
      comments: List<Comment9>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.postId = postId
      self.title = title
      self.comments = comments
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}