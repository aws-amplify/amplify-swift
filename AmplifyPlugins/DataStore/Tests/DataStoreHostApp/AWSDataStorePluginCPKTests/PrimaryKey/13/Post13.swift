// swiftlint:disable all
import Amplify
import Foundation

public struct Post13: Model {
  public let postId: String
  public let sk: Temporal.DateTime
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(postId: String,
      sk: Temporal.DateTime) {
    self.init(postId: postId,
      sk: sk,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(postId: String,
      sk: Temporal.DateTime,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.postId = postId
      self.sk = sk
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}