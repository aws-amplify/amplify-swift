// swiftlint:disable all
import Amplify
import Foundation

extension Comment14 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case post
    case author
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let comment14 = Comment14.keys
    
    model.authRules = [
      rule(allow: .public, operations: [.create, .update, .delete, .read])
    ]
    
    model.pluralName = "Comment14s"
    
    model.attributes(
      .primaryKey(fields: [comment14.id])
    )
    
    model.fields(
      .field(comment14.id, is: .required, ofType: .string),
      .field(comment14.content, is: .optional, ofType: .string),
      .belongsTo(comment14.post, is: .optional, ofType: Post14.self, targetNames: ["post14CommentsId"]),
      .belongsTo(comment14.author, is: .required, ofType: User14.self, targetNames: ["user14CommentsId"]),
      .field(comment14.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment14.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Comment14> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Comment14: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Comment14 {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var content: FieldPath<String>   {
      string("content") 
    }
  public var post: ModelPath<Post14>   {
      Post14.Path(name: "post", parent: self) 
    }
  public var author: ModelPath<User14>   {
      User14.Path(name: "author", parent: self) 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}
