// swiftlint:disable all
import Amplify
import Foundation

extension Customer8 {
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
    let customer8 = Customer8.keys
    
    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Customer8s"
    model.syncPluralName = "Customer8s"
    
    model.attributes(
      .index(fields: ["accountRepresentativeId"], name: "customer8sByAccountRepresentativeId"),
      .primaryKey(fields: [customer8.id])
    )
    
    model.fields(
      .field(customer8.id, is: .required, ofType: .string),
      .field(customer8.name, is: .optional, ofType: .string),
      .field(customer8.phoneNumber, is: .optional, ofType: .string),
      .field(customer8.accountRepresentativeId, is: .required, ofType: .string),
      .field(customer8.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(customer8.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Customer8> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Customer8: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Customer8 {
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