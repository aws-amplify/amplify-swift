// swiftlint:disable all
import Amplify
import Foundation

public struct Cart4: Model {
  public let id: String
  public var items: [String]?
  internal var _customer: LazyReference<Customer4>
  public var customer: Customer4?   {
      get async throws { 
        try await _customer.get()
      } 
    }
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      items: [String]? = nil,
      customer: Customer4? = nil) {
    self.init(id: id,
      items: items,
      customer: customer,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      items: [String]? = nil,
      customer: Customer4? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.items = items
      self._customer = LazyReference(customer)
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
  public mutating func setCustomer(_ customer: Customer4? = nil) {
    self._customer = LazyReference(customer)
  }
  public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      id = try values.decode(String.self, forKey: .id)
      items = try values.decode([String].self, forKey: .items)
      _customer = try values.decodeIfPresent(LazyReference<Customer4>.self, forKey: .customer) ?? LazyReference(identifiers: nil)
      createdAt = try? values.decode(Temporal.DateTime?.self, forKey: .createdAt)
      updatedAt = try? values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
  }
  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      try container.encode(items, forKey: .items)
      try container.encode(_customer, forKey: .customer)
      try container.encode(createdAt, forKey: .createdAt)
      try container.encode(updatedAt, forKey: .updatedAt)
  }
}