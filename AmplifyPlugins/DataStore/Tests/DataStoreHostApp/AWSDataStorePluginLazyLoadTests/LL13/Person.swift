// swiftlint:disable all
import Amplify
import Foundation

public struct Person: Model {
  public let id: String
  public var name: String
  public var callerOf: List<PhoneCall>?
  public var calleeOf: List<PhoneCall>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      name: String,
      callerOf: List<PhoneCall> = [],
      calleeOf: List<PhoneCall> = []) {
    self.init(id: id,
      name: name,
      callerOf: callerOf,
      calleeOf: calleeOf,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String,
      callerOf: List<PhoneCall> = [],
      calleeOf: List<PhoneCall> = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.callerOf = callerOf
      self.calleeOf = calleeOf
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
