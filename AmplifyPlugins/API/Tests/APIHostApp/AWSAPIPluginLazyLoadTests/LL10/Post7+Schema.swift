// swiftlint:disable all
import Amplify
import Foundation

extension Post7 {
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
    let post7 = Post7.keys
    
    model.pluralName = "Post7s"
    
    model.attributes(
      .index(fields: ["postId", "title"], name: nil),
      .primaryKey(fields: [post7.postId, post7.title])
    )
    
    model.fields(
      .field(post7.postId, is: .required, ofType: .string),
      .field(post7.title, is: .required, ofType: .string),
      .hasMany(post7.comments, is: .optional, ofType: Comment7.self, associatedWith: Comment7.keys.post),
      .field(post7.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post7.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Post7> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Post7: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Post7.IdentifierProtocol {
  public static func identifier(postId: String,
      title: String) -> Self {
    .make(fields:[(name: "postId", value: postId), (name: "title", value: title)])
  }
}
extension ModelPath where ModelType == Post7 {
  public var postId: FieldPath<String>   {
      string("postId")
    }
  public var title: FieldPath<String>   {
      string("title")
    }
  public var comments: ModelPath<Comment7>   {
      Comment7.Path(name: "comments", isCollection: true, parent: self)
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
