// swiftlint:disable all
import Amplify
import Foundation

extension Person41 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case editedPosts
    case authoredPosts
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let person41 = Person41.keys
    
    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Person41s"
    model.syncPluralName = "Person41s"
    
    model.attributes(
      .primaryKey(fields: [person41.id])
    )
    
    model.fields(
      .field(person41.id, is: .required, ofType: .string),
      .field(person41.name, is: .optional, ofType: .string),
      .hasMany(person41.editedPosts, is: .optional, ofType: Post41.self, associatedFields: [Post41.keys.editor]),
      .hasMany(person41.authoredPosts, is: .optional, ofType: Post41.self, associatedFields: [Post41.keys.author]),
      .field(person41.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(person41.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Person41> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Person41: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Person41 {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var name: FieldPath<String>   {
      string("name") 
    }
  public var editedPosts: ModelPath<Post41>   {
      Post41.Path(name: "editedPosts", isCollection: true, parent: self) 
    }
  public var authoredPosts: ModelPath<Post41>   {
      Post41.Path(name: "authoredPosts", isCollection: true, parent: self) 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}