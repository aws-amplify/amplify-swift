// swiftlint:disable all
import Amplify
import Foundation

public struct PostTagsWithCompositeKey: Model {
  public let id: String
  public var postWithTagsCompositeKey: PostWithTagsCompositeKey
  public var tagWithCompositeKey: TagWithCompositeKey
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      postWithTagsCompositeKey: PostWithTagsCompositeKey,
      tagWithCompositeKey: TagWithCompositeKey) {
    self.init(id: id,
      postWithTagsCompositeKey: postWithTagsCompositeKey,
      tagWithCompositeKey: tagWithCompositeKey,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      postWithTagsCompositeKey: PostWithTagsCompositeKey,
      tagWithCompositeKey: TagWithCompositeKey,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.postWithTagsCompositeKey = postWithTagsCompositeKey
      self.tagWithCompositeKey = tagWithCompositeKey
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}