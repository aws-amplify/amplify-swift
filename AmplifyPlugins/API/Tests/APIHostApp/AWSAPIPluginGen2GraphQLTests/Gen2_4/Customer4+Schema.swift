// swiftlint:disable all
import Amplify
import Foundation

extension Customer4 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case activeCart
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let customer4 = Customer4.keys
    
    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Customer4s"
    model.syncPluralName = "Customer4s"
    
    model.attributes(
      .primaryKey(fields: [customer4.id])
    )
    
    model.fields(
      .field(customer4.id, is: .required, ofType: .string),
      .field(customer4.name, is: .optional, ofType: .string),
      .hasOne(customer4.activeCart, is: .optional, ofType: Cart4.self, associatedWith: Cart4.keys.customer),
      .field(customer4.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(customer4.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Customer4> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Customer4: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Customer4 {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var name: FieldPath<String>   {
      string("name") 
    }
  public var activeCart: ModelPath<Cart4>   {
      Cart4.Path(name: "activeCart", parent: self) 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}
