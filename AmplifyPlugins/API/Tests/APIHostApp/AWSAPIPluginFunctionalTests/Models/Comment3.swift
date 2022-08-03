// swiftlint:disable all
import Amplify
import Foundation

public struct Comment3: Model {
  public let id: String
  public var postID: String
  public var content: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      postID: String,
      content: String) {
    self.init(id: id,
      postID: postID,
      content: content,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      postID: String,
      content: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.postID = postID
      self.content = content
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}