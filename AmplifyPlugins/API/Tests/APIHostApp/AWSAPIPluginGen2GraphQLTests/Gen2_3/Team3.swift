// swiftlint:disable all
import Amplify
import Foundation

public struct Team3: Model {
  public let id: String
  public var mantra: String
  public var members: List<Member3>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      mantra: String,
      members: List<Member3>? = []) {
    self.init(id: id,
      mantra: mantra,
      members: members,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      mantra: String,
      members: List<Member3>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.mantra = mantra
      self.members = members
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}