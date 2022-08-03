// swiftlint:disable all
import Amplify
import Foundation

extension Post4 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case comments
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let post4 = Post4.keys
    
    model.pluralName = "Post4s"
    
    model.fields(
      .id(),
      .field(post4.title, is: .required, ofType: .string),
      .hasMany(post4.comments, is: .optional, ofType: Comment4.self, associatedWith: Comment4.keys.post),
      .field(post4.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post4.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}