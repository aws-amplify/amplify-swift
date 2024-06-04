// swiftlint:disable all
import Amplify
import Foundation

extension Post1 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case location
    case content
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let post1 = Post1.keys
    
    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Post1s"
    model.syncPluralName = "Post1s"
    
    model.attributes(
      .primaryKey(fields: [post1.id])
    )
    
    model.fields(
      .field(post1.id, is: .required, ofType: .string),
      .field(post1.location, is: .optional, ofType: .embedded(type: Location1.self)),
      .field(post1.content, is: .optional, ofType: .string),
      .field(post1.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post1.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Post1> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Post1: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Post1 {
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