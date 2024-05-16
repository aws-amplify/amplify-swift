// swiftlint:disable all
import Amplify
import Foundation

extension Todo12 {
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
    let todo12 = Todo12.keys
    
    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Todo12s"
    model.syncPluralName = "Todo12s"
    
    model.attributes(
      .primaryKey(fields: [todo12.id])
    )
    
    model.fields(
      .field(todo12.id, is: .required, ofType: .string),
      .field(todo12.content, is: .optional, ofType: .string),
      .field(todo12.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todo12.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Todo12> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Todo12: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Todo12 {
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