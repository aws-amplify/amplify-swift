// swiftlint:disable all
import Amplify
import Foundation

extension Comment {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case post
    case content
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let comment = Comment.keys
    
    model.pluralName = "Comments"
    
    model.attributes(
      .primaryKey(fields: [comment.id])
    )
    
    model.fields(
      .field(comment.id, is: .required, ofType: .string),
      .belongsTo(comment.post, is: .optional, ofType: Post.self, targetNames: ["postCommentsId"]),
      .field(comment.content, is: .required, ofType: .string),
      .field(comment.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Comment: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
