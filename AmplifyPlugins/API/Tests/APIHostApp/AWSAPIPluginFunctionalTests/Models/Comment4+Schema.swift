// swiftlint:disable all
import Amplify
import Foundation

extension Comment4 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case post
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let comment4 = Comment4.keys
    
    model.pluralName = "Comment4s"
    
    model.attributes(
      .index(fields: ["postID", "content"], name: "byPost4")
    )
    
    model.fields(
      .id(),
      .field(comment4.content, is: .required, ofType: .string),
      .belongsTo(comment4.post, is: .optional, ofType: Post4.self, targetName: "postID"),
      .field(comment4.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment4.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}