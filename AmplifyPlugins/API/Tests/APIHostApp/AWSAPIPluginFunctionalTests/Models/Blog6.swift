// swiftlint:disable all
import Amplify
import Foundation

public struct Blog6: Model {
  public let id: String
  public var name: String
  public var posts: List<Post6>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      name: String,
      posts: List<Post6>? = []) {
    self.init(id: id,
      name: name,
      posts: posts,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String,
      posts: List<Post6>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.posts = posts
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}