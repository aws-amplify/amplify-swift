// swiftlint:disable all
import Amplify
import Foundation

extension CommentWithCompositeKey {
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
    let commentWithCompositeKey = CommentWithCompositeKey.keys
    
    model.pluralName = "CommentWithCompositeKeys"
    
    model.attributes(
      .index(fields: ["id", "content"], name: nil),
      .primaryKey(fields: [commentWithCompositeKey.id, commentWithCompositeKey.content])
    )
    
    model.fields(
      .field(commentWithCompositeKey.id, is: .required, ofType: .string),
      .field(commentWithCompositeKey.content, is: .required, ofType: .string),
      .belongsTo(commentWithCompositeKey.post, is: .optional, ofType: PostWithCompositeKey.self, targetNames: ["postWithCompositeKeyCommentsId", "postWithCompositeKeyCommentsTitle"]),
      .field(commentWithCompositeKey.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(commentWithCompositeKey.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<CommentWithCompositeKey> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension CommentWithCompositeKey: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension CommentWithCompositeKey.IdentifierProtocol {
  public static func identifier(id: String,
      content: String) -> Self {
    .make(fields:[(name: "id", value: id), (name: "content", value: content)])
  }
}
extension ModelPath where ModelType == CommentWithCompositeKey {
  public var id: FieldPath<String>   {
      string("id")
    }
  public var content: FieldPath<String>   {
      string("content")
    }
  public var post: ModelPath<PostWithCompositeKey>   {
      PostWithCompositeKey.Path(name: "post", parent: self)
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
