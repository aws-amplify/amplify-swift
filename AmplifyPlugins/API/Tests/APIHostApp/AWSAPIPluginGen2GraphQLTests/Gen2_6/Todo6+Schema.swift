// swiftlint:disable all
import Amplify
import Foundation

extension Todo6 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case todoId
    case content
    case completed
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let todo6 = Todo6.keys
    
    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Todo6s"
    model.syncPluralName = "Todo6s"
    
    model.attributes(
      .index(fields: ["todoId"], name: nil),
      .primaryKey(fields: [todo6.todoId])
    )
    
    model.fields(
      .field(todo6.todoId, is: .required, ofType: .string),
      .field(todo6.content, is: .optional, ofType: .string),
      .field(todo6.completed, is: .optional, ofType: .bool),
      .field(todo6.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todo6.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Todo6> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Todo6: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Todo6.IdentifierProtocol {
  public static func identifier(todoId: String) -> Self {
    .make(fields:[(name: "todoId", value: todoId)])
  }
}
extension ModelPath where ModelType == Todo6 {
  public var todoId: FieldPath<String>   {
      string("todoId") 
    }
  public var content: FieldPath<String>   {
      string("content") 
    }
  public var completed: FieldPath<Bool>   {
      bool("completed") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}