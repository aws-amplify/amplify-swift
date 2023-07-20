// swiftlint:disable all
import Amplify
import Foundation

extension Post12 {
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
    let post12 = Post12.keys
    
    model.pluralName = "Post12s"
    
    model.attributes(
      .index(fields: ["postId", "sk"], name: nil),
      .primaryKey(fields: [post12.postId, post12.sk])
    )
    
    model.fields(
      .field(post12.postId, is: .required, ofType: .string),
      .field(post12.sk, is: .required, ofType: .double),
      .field(post12.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post12.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Post12: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Post12.IdentifierProtocol {
  public static func identifier(postId: String,
      sk: Double) -> Self {
    .make(fields:[(name: "postId", value: postId), (name: "sk", value: sk)])
  }
}