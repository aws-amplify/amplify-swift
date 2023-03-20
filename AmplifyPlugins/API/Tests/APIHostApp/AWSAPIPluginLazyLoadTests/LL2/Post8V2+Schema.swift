// swiftlint:disable all
import Amplify
import Foundation

extension Post8V2 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case randomId
    case blog
    case comments
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let post8V2 = Post8V2.keys
    
    model.pluralName = "Post8V2s"
    
    model.attributes(
      .index(fields: ["blogId"], name: "postByBlog"),
      .index(fields: ["randomId"], name: "byRandom"),
      .primaryKey(fields: [post8V2.id])
    )
    
    model.fields(
      .field(post8V2.id, is: .required, ofType: .string),
      .field(post8V2.name, is: .required, ofType: .string),
      .field(post8V2.randomId, is: .optional, ofType: .string),
      .belongsTo(post8V2.blog, is: .optional, ofType: Blog8V2.self, targetNames: ["blogId"]),
      .hasMany(post8V2.comments, is: .optional, ofType: Comment8V2.self, associatedWith: Comment8V2.keys.post),
      .field(post8V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post8V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    
    public class Path: ModelPath<Post8V2> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Post8V2: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}

extension ModelPath where ModelType == Post8V2 {
    var id: FieldPath<String> { id() }
    var name: FieldPath<String> { string("name") }
    var randomId: FieldPath<String> { string("randomId") }
    var blog: ModelPath<Blog8V2> { Blog8V2.Path(name: "blog", parent: self) }
    var comments: ModelPath<Comment8V2> { Comment8V2.Path(name: "comments", isCollection: true, parent: self) }
    var createdAt: FieldPath<Temporal.DateTime> { datetime("createdAt") }
    var updatedAt: FieldPath<Temporal.DateTime> { datetime("updatedAt") }
}
