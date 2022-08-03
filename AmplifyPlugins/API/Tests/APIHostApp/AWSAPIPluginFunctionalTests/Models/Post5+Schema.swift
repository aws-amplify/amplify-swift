// swiftlint:disable all
import Amplify
import Foundation

extension Post5 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case editors
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let post5 = Post5.keys
    
    model.pluralName = "Post5s"
    
    model.fields(
      .id(),
      .field(post5.title, is: .required, ofType: .string),
      .hasMany(post5.editors, is: .optional, ofType: PostEditor5.self, associatedWith: PostEditor5.keys.post),
      .field(post5.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post5.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}