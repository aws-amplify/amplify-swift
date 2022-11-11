// swiftlint:disable all
import Amplify
import Foundation

extension Post8 {
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
    let post8 = Post8.keys
    
    model.pluralName = "Post8s"
    
    model.attributes(
      .index(fields: ["postId", "title"], name: nil),
      .primaryKey(fields: [post8.postId, post8.title])
    )
    
    model.fields(
      .field(post8.postId, is: .required, ofType: .string),
      .field(post8.title, is: .required, ofType: .string),
      .hasMany(post8.comments, is: .optional, ofType: Comment8.self, associatedWith: Comment8.keys.postId),
      .field(post8.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post8.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    
    public class Path: ModelPath<Post8> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Post8: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Post8.IdentifierProtocol {
  public static func identifier(postId: String,
      title: String) -> Self {
    .make(fields:[(name: "postId", value: postId), (name: "title", value: title)])
  }
}

extension ModelPath where ModelType == Post8 {
    var postId: FieldPath<String> { string("postId") }
    var title: FieldPath<String> { string("title") }
    var comments: ModelPath<Comment8> { Comment8.Path(name: "comments", isCollection: true, parent: self) }
    var createdAt: FieldPath<Temporal.DateTime> { datetime("createdAt") }
    var updatedAt: FieldPath<Temporal.DateTime> { datetime("updatedAt") }
}
