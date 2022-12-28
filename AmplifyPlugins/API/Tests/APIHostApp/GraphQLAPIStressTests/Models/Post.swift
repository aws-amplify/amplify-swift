// swiftlint:disable all
import Amplify
import Foundation

public struct Post: Model {
  public let id: String
  public var title: String
  public var status: PostStatus
  public var rating: Int?
  public var content: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      title: String,
      status: PostStatus,
      rating: Int? = nil,
      content: String? = nil) {
    self.init(id: id,
      title: title,
      status: status,
      rating: rating,
      content: content,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      title: String,
      status: PostStatus,
      rating: Int? = nil,
      content: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.title = title
      self.status = status
      self.rating = rating
      self.content = content
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}