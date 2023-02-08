// swiftlint:disable all
import Amplify
import Foundation

extension Comment4 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case commentId
    case content
    case createdAt
    case updatedAt
    case post4CommentsPostId
    case post4CommentsTitle
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let comment4 = Comment4.keys
    
    model.pluralName = "Comment4s"
    
    model.attributes(
      .index(fields: ["commentId", "content"], name: nil),
      .primaryKey(fields: [comment4.commentId, comment4.content])
    )
    
    model.fields(
      .field(comment4.commentId, is: .required, ofType: .string),
      .field(comment4.content, is: .required, ofType: .string),
      .field(comment4.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment4.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment4.post4CommentsPostId, is: .optional, ofType: .string),
      .field(comment4.post4CommentsTitle, is: .optional, ofType: .string)
    )
    }
    public class Path: ModelPath<Comment4> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Comment4: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Comment4.IdentifierProtocol {
  public static func identifier(commentId: String,
      content: String) -> Self {
    .make(fields:[(name: "commentId", value: commentId), (name: "content", value: content)])
  }
}

extension ModelPath where ModelType == Comment4 {
    var commentId: FieldPath<String> { string("commentId") }
    var content: FieldPath<String> { string("content") }
    var createdAt: FieldPath<Temporal.DateTime> { datetime("createdAt") }
    var updatedAt: FieldPath<Temporal.DateTime> { datetime("updatedAt") }
    var post4CommentsPostId: FieldPath<String> { string("post4CommentsPostId") }
    var post4CommentsTitle: FieldPath<String> { string("post4CommentsTitle") }
    
}
