// swiftlint:disable all
import Amplify
import Foundation

extension Comment4V2 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case post
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let comment4V2 = Comment4V2.keys
    
    model.authRules = [
      rule(allow: .public, operations: [.create, .update, .delete, .read])
    ]
    
    model.pluralName = "Comment4V2s"
    
    model.attributes(
      .index(fields: ["postID", "content"], name: "byPost4"),
      .primaryKey(fields: [comment4V2.id])
    )
    
    model.fields(
      .field(comment4V2.id, is: .required, ofType: .string),
      .field(comment4V2.content, is: .required, ofType: .string),
      .belongsTo(comment4V2.post, is: .optional, ofType: Post4V2.self, targetNames: ["postID"]),
      .field(comment4V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment4V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    
    public class Path: ModelPath<Comment4V2> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Comment4V2: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}

extension ModelPath where ModelType == Comment4V2 {
    var id: FieldPath<String> { id() }
    var content: FieldPath<String> { string("content") }
    var post: ModelPath<Post4V2> { Post4V2.Path(name: "post", parent: self) }
    var createdAt: FieldPath<Temporal.DateTime> { datetime("createdAt") }
    var updatedAt: FieldPath<Temporal.DateTime> { datetime("updatedAt") }
}
