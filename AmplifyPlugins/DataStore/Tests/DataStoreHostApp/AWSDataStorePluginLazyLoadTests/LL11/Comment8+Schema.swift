// swiftlint:disable all
import Amplify
import Foundation

extension Comment8 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case commentId
    case content
    case postId
    case postTitle
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let comment8 = Comment8.keys
    
    model.pluralName = "Comment8s"
    
    model.attributes(
      .index(fields: ["commentId", "content"], name: nil),
      .index(fields: ["postId", "postTitle"], name: "byPost"),
      .primaryKey(fields: [comment8.commentId, comment8.content])
    )
    
    model.fields(
      .field(comment8.commentId, is: .required, ofType: .string),
      .field(comment8.content, is: .required, ofType: .string),
      .field(comment8.postId, is: .optional, ofType: .string),
      .field(comment8.postTitle, is: .optional, ofType: .string),
      .field(comment8.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment8.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Comment8: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Comment8.IdentifierProtocol {
  public static func identifier(commentId: String,
      content: String) -> Self {
    .make(fields:[(name: "commentId", value: commentId), (name: "content", value: content)])
  }
}