// swiftlint:disable all
import Amplify
import Foundation

extension Customer9 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case phoneNumber
    case accountRepresentativeId
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let customer9 = Customer9.keys
    
    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Customer9s"
    model.syncPluralName = "Customer9s"
    
    model.attributes(
      .index(fields: ["accountRepresentativeId", "name"], name: "customer9sByAccountRepresentativeIdAndName"),
      .primaryKey(fields: [customer9.id])
    )
    
    model.fields(
      .field(customer9.id, is: .required, ofType: .string),
      .field(customer9.name, is: .optional, ofType: .string),
      .field(customer9.phoneNumber, is: .optional, ofType: .string),
      .field(customer9.accountRepresentativeId, is: .required, ofType: .string),
      .field(customer9.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(customer9.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Customer9> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Customer9: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Customer9 {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var name: FieldPath<String>   {
      string("name") 
    }
  public var phoneNumber: FieldPath<String>   {
      string("phoneNumber") 
    }
  public var accountRepresentativeId: FieldPath<String>   {
      string("accountRepresentativeId") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}