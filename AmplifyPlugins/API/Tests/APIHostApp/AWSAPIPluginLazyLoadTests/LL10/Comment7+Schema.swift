// swiftlint:disable all
import Amplify
import Foundation

extension Comment7 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case commentId
    case content
    case post
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema
  
  public static let schema = defineSchema { model in
    let comment7 = Comment7.keys
    
    model.pluralName = "Comment7s"
    
    model.attributes(
      .index(fields: ["commentId", "content"], name: nil),
      .index(fields: ["postId", "postTitle"], name: "byPost"),
      .primaryKey(fields: [comment7.commentId, comment7.content])
    )
    
    model.fields(
      .field(comment7.commentId, is: .required, ofType: .string),
      .field(comment7.content, is: .required, ofType: .string),
      .belongsTo(comment7.post, is: .optional, ofType: Post7.self, targetNames: ["postId", "postTitle"]),
      .field(comment7.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment7.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Comment7> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Comment7: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Comment7.IdentifierProtocol {
  public static func identifier(commentId: String,
      content: String) -> Self {
    .make(fields:[(name: "commentId", value: commentId), (name: "content", value: content)])
  }
}
extension ModelPath where ModelType == Comment7 {
  public var commentId: FieldPath<String>   {
      string("commentId")
    }
  public var content: FieldPath<String>   {
      string("content")
    }
  public var post: ModelPath<Post7>   {
      Post7.Path(name: "post", parent: self)
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
