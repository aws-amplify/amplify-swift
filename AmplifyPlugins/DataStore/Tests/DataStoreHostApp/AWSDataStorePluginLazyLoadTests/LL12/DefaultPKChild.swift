// swiftlint:disable all
import Amplify
import Foundation

public struct DefaultPKChild: Model {
  public let id: String
  public var content: String?
  public var parent: DefaultPKParent?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      content: String? = nil,
      parent: DefaultPKParent? = nil) {
    self.init(id: id,
      content: content,
      parent: parent,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      content: String? = nil,
      parent: DefaultPKParent? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.content = content
      self.parent = parent
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}