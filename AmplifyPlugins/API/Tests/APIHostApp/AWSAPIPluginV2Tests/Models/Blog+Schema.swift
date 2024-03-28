// swiftlint:disable all
import Amplify
import Foundation

extension Blog {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case posts
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let blog = Blog.keys
    
    model.pluralName = "Blogs"
    
    model.attributes(
      .primaryKey(fields: [blog.id])
    )
    
    model.fields(
      .field(blog.id, is: .required, ofType: .string),
      .field(blog.name, is: .required, ofType: .string),
      .hasMany(blog.posts, is: .optional, ofType: Post.self, associatedWith: Post.keys.blog),
      .field(blog.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(blog.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Blog: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
