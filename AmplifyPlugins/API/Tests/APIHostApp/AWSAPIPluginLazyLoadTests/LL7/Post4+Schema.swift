// swiftlint:disable all
import Amplify
import Foundation

extension Post4 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case postId
    case title
    case comments
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema
  
  public static let schema = defineSchema { model in
    let post4 = Post4.keys
    
    model.pluralName = "Post4s"
    
    model.attributes(
      .index(fields: ["postId", "title"], name: nil),
      .primaryKey(fields: [post4.postId, post4.title])
    )
    
    model.fields(
      .field(post4.postId, is: .required, ofType: .string),
      .field(post4.title, is: .required, ofType: .string),
      .hasMany(post4.comments, is: .optional, ofType: Comment4.self, associatedFields: [Comment4.keys.post4CommentsPostId, Comment4.keys.post4CommentsTitle]),
      .field(post4.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post4.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Post4> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Post4: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Post4.IdentifierProtocol {
  public static func identifier(postId: String,
      title: String) -> Self {
    .make(fields:[(name: "postId", value: postId), (name: "title", value: title)])
  }
}
extension ModelPath where ModelType == Post4 {
  public var postId: FieldPath<String>   {
      string("postId")
    }
  public var title: FieldPath<String>   {
      string("title")
    }
  public var comments: ModelPath<Comment4>   {
      Comment4.Path(name: "comments", isCollection: true, parent: self)
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
