// swiftlint:disable all
import Amplify
import Foundation

public struct Post6: Model {
  public let id: String
  public var title: String
  public var blog: Blog6?
  public var comments: List<Comment6>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      title: String,
      blog: Blog6? = nil,
      comments: List<Comment6>? = []) {
    self.init(id: id,
      title: title,
      blog: blog,
      comments: comments,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      title: String,
      blog: Blog6? = nil,
      comments: List<Comment6>? = [],
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