// swiftlint:disable all
import Amplify
import Foundation

extension PostWithCompositeKey {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case comments
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let postWithCompositeKey = PostWithCompositeKey.keys
    
    model.pluralName = "PostWithCompositeKeys"
    
    model.attributes(
      .index(fields: ["id", "title"], name: nil),
      .primaryKey(fields: [postWithCompositeKey.id, postWithCompositeKey.title])
    )
    
    model.fields(
      .field(postWithCompositeKey.id, is: .required, ofType: .string),
      .field(postWithCompositeKey.title, is: .required, ofType: .string),
      .hasMany(postWithCompositeKey.comments, is: .optional, ofType: CommentWithCompositeKey.self, associatedWith: CommentWithCompositeKey.keys.post),
      .field(postWithCompositeKey.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(postWithCompositeKey.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension PostWithCompositeKey: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension PostWithCompositeKey.IdentifierProtocol {
  public static func identifier(id: String,
      title: String) -> Self {
    .make(fields:[(name: "id", value: id), (name: "title", value: title)])
  }
}