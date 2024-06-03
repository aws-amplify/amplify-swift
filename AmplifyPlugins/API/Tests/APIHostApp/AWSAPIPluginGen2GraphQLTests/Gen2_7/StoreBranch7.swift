// swiftlint:disable all
import Amplify
import Foundation

public struct StoreBranch7: Model {
  public let tenantId: String
  public let name: String
  public var country: String?
  public var state: String?
  public var city: String?
  public var zipCode: String?
  public var streetAddress: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(tenantId: String,
      name: String,
      country: String? = nil,
      state: String? = nil,
      city: String? = nil,
      zipCode: String? = nil,
      streetAddress: String? = nil) {
    self.init(tenantId: tenantId,
      name: name,
      country: country,
      state: state,
      city: city,
      zipCode: zipCode,
      streetAddress: streetAddress,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(tenantId: String,
      name: String,
      country: String? = nil,
      state: String? = nil,
      city: String? = nil,
      zipCode: String? = nil,
      streetAddress: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.tenantId = tenantId
      self.name = name
      self.country = country
      self.state = state
      self.city = city
      self.zipCode = zipCode
      self.streetAddress = streetAddress
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}