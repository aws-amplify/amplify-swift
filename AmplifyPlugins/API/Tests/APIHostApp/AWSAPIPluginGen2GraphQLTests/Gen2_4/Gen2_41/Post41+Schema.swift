// swiftlint:disable all
import Amplify
import Foundation

extension Post41 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case content
    case author
    case editor
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let post41 = Post41.keys
    
    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Post41s"
    model.syncPluralName = "Post41s"
    
    model.attributes(
      .primaryKey(fields: [post41.id])
    )
    
    model.fields(
      .field(post41.id, is: .required, ofType: .string),
      .field(post41.title, is: .required, ofType: .string),
      .field(post41.content, is: .required, ofType: .string),
      .belongsTo(post41.author, is: .optional, ofType: Person41.self, targetNames: ["authorId"]),
      .belongsTo(post41.editor, is: .optional, ofType: Person41.self, targetNames: ["editorId"]),
      .field(post41.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post41.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Post41> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Post41: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Post41 {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var title: FieldPath<String>   {
      string("title") 
    }
  public var content: FieldPath<String>   {
      string("content") 
    }
  public var author: ModelPath<Person41>   {
      Person41.Path(name: "author", parent: self) 
    }
  public var editor: ModelPath<Person41>   {
      Person41.Path(name: "editor", parent: self) 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}