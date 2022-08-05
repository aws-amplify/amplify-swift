// swiftlint:disable all
import Amplify
import Foundation

public struct Post5: Model {
  public let id: String
  public var title: String
  public var editors: List<PostEditor5>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      title: String,
      editors: List<PostEditor5>? = []) {
    self.init(id: id,
      title: title,
      editors: editors,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      title: String,
      editors: List<PostEditor5>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.title = title
      self.editors = editors
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}