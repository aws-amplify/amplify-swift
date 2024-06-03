// swiftlint:disable all
import Amplify
import Foundation

extension Todo16 {
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
    let todo16 = Todo16.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Todo16s"
    model.syncPluralName = "Todo16s"
    
    model.attributes(
      .primaryKey(fields: [todo16.id])
    )
    
    model.fields(
      .field(todo16.id, is: .required, ofType: .string),
      .field(todo16.content, is: .optional, ofType: .string),
      .field(todo16.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todo16.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Todo16> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Todo16: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Todo16 {
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