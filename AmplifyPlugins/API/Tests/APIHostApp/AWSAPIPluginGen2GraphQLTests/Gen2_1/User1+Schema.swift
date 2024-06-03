// swiftlint:disable all
import Amplify
import Foundation

extension User1 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case lastKnownLocation
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let user1 = User1.keys
    
    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "User1s"
    model.syncPluralName = "User1s"
    
    model.attributes(
      .primaryKey(fields: [user1.id])
    )
    
    model.fields(
      .field(user1.id, is: .required, ofType: .string),
      .field(user1.lastKnownLocation, is: .optional, ofType: .embedded(type: Location1.self)),
      .field(user1.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(user1.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<User1> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension User1: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == User1 {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}