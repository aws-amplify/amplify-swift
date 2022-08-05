// swiftlint:disable all
import Amplify
import Foundation

extension PostEditor5 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case post
    case editor
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let postEditor5 = PostEditor5.keys
    
    model.pluralName = "PostEditor5s"
    
    model.attributes(
      .index(fields: ["postID", "editorID"], name: "byPost5"),
      .index(fields: ["editorID", "postID"], name: "byEditor5")
    )
    
    model.fields(
      .id(),
      .belongsTo(postEditor5.post, is: .required, ofType: Post5.self, targetName: "postID"),
      .belongsTo(postEditor5.editor, is: .required, ofType: User5.self, targetName: "editorID"),
      .field(postEditor5.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(postEditor5.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}