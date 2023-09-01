// swiftlint:disable all
import Amplify
import Foundation

extension Post20 {
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
    let post20 = Post20.keys
    
    model.pluralName = "Post20s"
    
    model.attributes(
      .index(fields: ["postId", "sk"], name: nil),
      .primaryKey(fields: [post20.postId, post20.sk])
    )
    
    model.fields(
      .field(post20.postId, is: .required, ofType: .string),
      .field(post20.sk, is: .required, ofType: .int),
      .field(post20.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post20.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Post20: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Post20.IdentifierProtocol {
  public static func identifier(postId: String,
      sk: Int) -> Self {
    .make(fields:[(name: "postId", value: postId), (name: "sk", value: sk)])
  }
}