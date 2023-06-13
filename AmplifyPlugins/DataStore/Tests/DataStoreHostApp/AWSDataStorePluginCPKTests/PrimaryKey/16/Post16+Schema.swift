// swiftlint:disable all
import Amplify
import Foundation

extension Post16 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case postId
    case sk
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let post16 = Post16.keys
    
    model.pluralName = "Post16s"
    
    model.attributes(
      .index(fields: ["postId", "sk"], name: nil),
      .primaryKey(fields: [post16.postId, post16.sk])
    )
    
    model.fields(
      .field(post16.postId, is: .required, ofType: .string),
      .field(post16.sk, is: .required, ofType: .string),
      .field(post16.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post16.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Post16: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Post16.IdentifierProtocol {
  public static func identifier(postId: String,
      sk: String) -> Self {
    .make(fields:[(name: "postId", value: postId), (name: "sk", value: sk)])
  }
}