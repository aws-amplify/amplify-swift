// swiftlint:disable all
import Amplify
import Foundation

public struct CommentWithCompositeKey: Model {
  public let id: String
  public var content: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var post21CommentsId: String?
  public var post21CommentsTitle: String?
  
  public init(id: String = UUID().uuidString,
              content: String,
              post21CommentsId: String? = nil,
              post21CommentsTitle: String?) {
    self.init(id: id,
              content: content,
              createdAt: nil,
              updatedAt: nil,
              post21CommentsId: post21CommentsId,
              post21CommentsTitle: post21CommentsTitle)
  }
  internal init(id: String = UUID().uuidString,
                content: String,
                createdAt: Temporal.DateTime? = nil,
                updatedAt: Temporal.DateTime? = nil,
                post21CommentsId: String? = nil,
                post21CommentsTitle: String?) {
      self.id = id
      self.content = content
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.post21CommentsId = post21CommentsId
      self.post21CommentsTitle = post21CommentsTitle
  }
}
