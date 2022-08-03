// swiftlint:disable all
import Amplify
import Foundation

extension User5 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case username
    case posts
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let user5 = User5.keys
    
    model.pluralName = "User5s"
    
    model.fields(
      .id(),
      .field(user5.username, is: .required, ofType: .string),
      .hasMany(user5.posts, is: .optional, ofType: PostEditor5.self, associatedWith: PostEditor5.keys.editor),
      .field(user5.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(user5.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}