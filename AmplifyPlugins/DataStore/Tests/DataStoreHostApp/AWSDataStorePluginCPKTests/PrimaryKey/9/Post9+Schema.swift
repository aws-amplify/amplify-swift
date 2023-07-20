// swiftlint:disable all
import Amplify
import Foundation

extension Post9 {
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
    let post9 = Post9.keys
    
    model.pluralName = "Post9s"
    
    model.attributes(
      .index(fields: ["postId"], name: nil),
      .primaryKey(fields: [post9.postId])
    )
    
    model.fields(
      .field(post9.postId, is: .required, ofType: .string),
      .field(post9.title, is: .optional, ofType: .string),
      .hasMany(post9.comments, is: .optional, ofType: Comment9.self, associatedWith: Comment9.keys.postId),
      .field(post9.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post9.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Post9: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Post9.IdentifierProtocol {
  public static func identifier(postId: String) -> Self {
    .make(fields:[(name: "postId", value: postId)])
  }
}