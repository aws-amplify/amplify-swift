// swiftlint:disable all
import Amplify
import Foundation

extension Comment8V2 {
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
    let comment8V2 = Comment8V2.keys
    
    model.pluralName = "Comment8V2s"
    
    model.attributes(
      .index(fields: ["postId"], name: "commentByPost"),
      .primaryKey(fields: [comment8V2.id])
    )
    
    model.fields(
      .field(comment8V2.id, is: .required, ofType: .string),
      .field(comment8V2.content, is: .optional, ofType: .string),
      .belongsTo(comment8V2.post, is: .optional, ofType: Post8V2.self, targetNames: ["postId"]),
      .field(comment8V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment8V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Comment8V2> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Comment8V2: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Comment8V2 {
  public var id: FieldPath<String>   {
      string("id")
    }
  public var content: FieldPath<String>   {
      string("content")
    }
  public var post: ModelPath<Post8V2>   {
      Post8V2.Path(name: "post", parent: self)
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
