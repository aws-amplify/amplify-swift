// swiftlint:disable all
import Amplify
import Foundation

public struct Post: Model {
  public let id: String
  public var title: String
  public var content: String
  public var createdAt: Temporal.DateTime
  public var updatedAt: Temporal.DateTime?
  public var draft: Bool?
  public var rating: Double?
  public var status: PostStatus?
  public var comments: List<Comment>?
  
  public init(id: String = UUID().uuidString,
      title: String,
      content: String,
      createdAt: Temporal.DateTime,
      updatedAt: Temporal.DateTime? = nil,
      draft: Bool? = nil,
      rating: Double? = nil,
      status: PostStatus? = nil,
      comments: List<Comment>? = []) {
      self.id = id
      self.title = title
      self.content = content
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.draft = draft
      self.rating = rating
      self.status = status
      self.comments = comments
  }
}