// swiftlint:disable all
import Amplify
import Foundation

extension Post17 {
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
    let post17 = Post17.keys
    
    model.pluralName = "Post17s"
    
    model.attributes(
      .index(fields: ["postId", "sk"], name: nil),
      .primaryKey(fields: [post17.postId, post17.sk])
    )
    
    model.fields(
      .field(post17.postId, is: .required, ofType: .string),
      .field(post17.sk, is: .required, ofType: .string),
      .field(post17.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post17.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Post17: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Post17.IdentifierProtocol {
  public static func identifier(postId: String,
      sk: String) -> Self {
    .make(fields:[(name: "postId", value: postId), (name: "sk", value: sk)])
  }
}