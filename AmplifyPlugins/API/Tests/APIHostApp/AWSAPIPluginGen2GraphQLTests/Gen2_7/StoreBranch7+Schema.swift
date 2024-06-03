// swiftlint:disable all
import Amplify
import Foundation

extension StoreBranch7 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case tenantId
    case name
    case country
    case state
    case city
    case zipCode
    case streetAddress
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let storeBranch7 = StoreBranch7.keys
    
    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "StoreBranch7s"
    model.syncPluralName = "StoreBranch7s"
    
    model.attributes(
      .index(fields: ["tenantId", "name"], name: nil),
      .primaryKey(fields: [storeBranch7.tenantId, storeBranch7.name])
    )
    
    model.fields(
      .field(storeBranch7.tenantId, is: .required, ofType: .string),
      .field(storeBranch7.name, is: .required, ofType: .string),
      .field(storeBranch7.country, is: .optional, ofType: .string),
      .field(storeBranch7.state, is: .optional, ofType: .string),
      .field(storeBranch7.city, is: .optional, ofType: .string),
      .field(storeBranch7.zipCode, is: .optional, ofType: .string),
      .field(storeBranch7.streetAddress, is: .optional, ofType: .string),
      .field(storeBranch7.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(storeBranch7.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<StoreBranch7> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension StoreBranch7: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension StoreBranch7.IdentifierProtocol {
  public static func identifier(tenantId: String,
      name: String) -> Self {
    .make(fields:[(name: "tenantId", value: tenantId), (name: "name", value: name)])
  }
}
extension ModelPath where ModelType == StoreBranch7 {
  public var tenantId: FieldPath<String>   {
      string("tenantId") 
    }
  public var name: FieldPath<String>   {
      string("name") 
    }
  public var country: FieldPath<String>   {
      string("country") 
    }
  public var state: FieldPath<String>   {
      string("state") 
    }
  public var city: FieldPath<String>   {
      string("city") 
    }
  public var zipCode: FieldPath<String>   {
      string("zipCode") 
    }
  public var streetAddress: FieldPath<String>   {
      string("streetAddress") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}