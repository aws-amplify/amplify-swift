// swiftlint:disable all
import Amplify
import Foundation

public struct Blog8V2: Model {
  public let id: String
  public var name: String
  public var customs: [MyCustomModel8?]?
  public var notes: [String?]?
  public var posts: List<Post8V2>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      name: String,
      customs: [MyCustomModel8?]? = nil,
      notes: [String?]? = nil,
      posts: List<Post8V2>? = []) {
    self.init(id: id,
      name: name,
      customs: customs,
      notes: notes,
      posts: posts,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String,
      customs: [MyCustomModel8?]? = nil,
      notes: [String?]? = nil,
      posts: List<Post8V2>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.customs = customs
      self.notes = notes
      self.posts = posts
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}