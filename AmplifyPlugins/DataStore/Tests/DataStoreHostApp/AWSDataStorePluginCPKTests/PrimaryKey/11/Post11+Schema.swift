// swiftlint:disable all
import Amplify
import Foundation

extension Post11 {
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
    let post11 = Post11.keys
    
    model.pluralName = "Post11s"
    
    model.attributes(
      .index(fields: ["postId", "sk"], name: nil),
      .primaryKey(fields: [post11.postId, post11.sk])
    )
    
    model.fields(
      .field(post11.postId, is: .required, ofType: .string),
      .field(post11.sk, is: .required, ofType: .int),
      .field(post11.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post11.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Post11: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Post11.IdentifierProtocol {
  public static func identifier(postId: String,
      sk: Int) -> Self {
    .make(fields:[(name: "postId", value: postId), (name: "sk", value: sk)])
  }
}