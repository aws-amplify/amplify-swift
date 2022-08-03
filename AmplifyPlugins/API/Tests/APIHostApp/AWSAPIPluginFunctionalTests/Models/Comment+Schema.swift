// swiftlint:disable all
import Amplify
import Foundation

extension Comment {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case createdAt
    case post
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let comment = Comment.keys
    
    model.pluralName = "Comments"
    
    model.fields(
      .id(),
      .field(comment.content, is: .required, ofType: .string),
      .field(comment.createdAt, is: .required, ofType: .dateTime),
      .belongsTo(comment.post, is: .optional, ofType: Post.self, targetName: "commentPostId"),
      .field(comment.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}