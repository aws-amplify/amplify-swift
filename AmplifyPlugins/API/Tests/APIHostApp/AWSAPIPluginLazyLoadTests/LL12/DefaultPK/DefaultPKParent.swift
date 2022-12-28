// swiftlint:disable all
import Amplify
import Foundation

public struct DefaultPKParent: Model {
  public let id: String
  public var content: String?
  public var children: List<DefaultPKChild>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      content: String? = nil,
      children: List<DefaultPKChild>? = []) {
    self.init(id: id,
      content: content,
      children: children,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      content: String? = nil,
      children: List<DefaultPKChild>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.content = content
      self.children = children
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
