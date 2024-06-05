// swiftlint:disable all
import Amplify
import Foundation

public struct Customer8: Model {
  public let id: String
  public var name: String?
  public var phoneNumber: String?
  public var accountRepresentativeId: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      name: String? = nil,
      phoneNumber: String? = nil,
      accountRepresentativeId: String) {
    self.init(id: id,
      name: name,
      phoneNumber: phoneNumber,
      accountRepresentativeId: accountRepresentativeId,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String? = nil,
      phoneNumber: String? = nil,
      accountRepresentativeId: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.phoneNumber = phoneNumber
      self.accountRepresentativeId = accountRepresentativeId
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}