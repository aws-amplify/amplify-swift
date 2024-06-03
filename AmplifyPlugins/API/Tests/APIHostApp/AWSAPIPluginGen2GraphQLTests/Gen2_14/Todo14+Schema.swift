// swiftlint:disable all
import Amplify
import Foundation

extension Todo14 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let todo14 = Todo14.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .read, .update])
    ]
    
    model.listPluralName = "Todo14s"
    model.syncPluralName = "Todo14s"
    
    model.attributes(
      .primaryKey(fields: [todo14.id])
    )
    
    model.fields(
      .field(todo14.id, is: .required, ofType: .string),
      .field(todo14.content, is: .optional, ofType: .string),
      .field(todo14.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todo14.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Todo14> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Todo14: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Todo14 {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var content: FieldPath<String>   {
      string("content") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}