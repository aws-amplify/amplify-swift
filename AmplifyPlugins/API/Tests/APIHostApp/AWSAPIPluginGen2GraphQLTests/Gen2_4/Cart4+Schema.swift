// swiftlint:disable all
import Amplify
import Foundation

extension Cart4 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case items
    case customer
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let cart4 = Cart4.keys
    
    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Cart4s"
    model.syncPluralName = "Cart4s"
    
    model.attributes(
      .primaryKey(fields: [cart4.id])
    )
    
    model.fields(
      .field(cart4.id, is: .required, ofType: .string),
      .field(cart4.items, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .belongsTo(cart4.customer, is: .optional, ofType: Customer4.self, targetNames: ["customerId"]),
      .field(cart4.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(cart4.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Cart4> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Cart4: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Cart4 {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var items: FieldPath<String>   {
      string("items") 
    }
  public var customer: ModelPath<Customer4>   {
      Customer4.Path(name: "customer", parent: self) 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}