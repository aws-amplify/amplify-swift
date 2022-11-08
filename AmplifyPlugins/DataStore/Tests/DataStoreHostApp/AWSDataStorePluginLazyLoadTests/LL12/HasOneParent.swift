// swiftlint:disable all
import Amplify
import Foundation

public struct HasOneParent: Model {
  public let id: String
  public var child: HasOneChild?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  public var hasOneParentChildId: String?
  
  public init(id: String = UUID().uuidString,
      child: HasOneChild? = nil,
      hasOneParentChildId: String? = nil) {
    self.init(id: id,
      child: child,
      createdAt: nil,
      updatedAt: nil,
      hasOneParentChildId: hasOneParentChildId)
  }
  internal init(id: String = UUID().uuidString,
      child: HasOneChild? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil,
      hasOneParentChildId: String? = nil) {
      self.id = id
      self.child = child
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.hasOneParentChildId = hasOneParentChildId
  }
}