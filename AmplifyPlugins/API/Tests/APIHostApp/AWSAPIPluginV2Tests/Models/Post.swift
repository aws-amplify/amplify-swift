// swiftlint:disable all
import Amplify
import Foundation

public struct Post: Model {
  public let id: String
  public var title: String
  public var blog: Blog?
  public var comments: List<Comment>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      title: String,
      blog: Blog? = nil,
      comments: List<Comment>? = []) {
    self.init(id: id,
      title: title,
      blog: blog,
      comments: comments,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      title: String,
      blog: Blog? = nil,
      comments: List<Comment>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.title = title
      self.blog = blog
      self.comments = comments
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
