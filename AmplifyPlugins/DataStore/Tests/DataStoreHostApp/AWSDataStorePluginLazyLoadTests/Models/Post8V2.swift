// swiftlint:disable all
import Amplify
import Foundation

public struct Post8V2: Model {
  public let id: String
  public var name: String
  public var randomId: String?
  public var blog: Blog8V2?
  public var comments: List<Comment8V2>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      name: String,
      randomId: String? = nil,
      blog: Blog8V2? = nil,
      comments: List<Comment8V2>? = []) {
    self.init(id: id,
      name: name,
      randomId: randomId,
      blog: blog,
      comments: comments,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String,
      randomId: String? = nil,
      blog: Blog8V2? = nil,
      comments: List<Comment8V2>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.randomId = randomId
      self.blog = blog
      self.comments = comments
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}