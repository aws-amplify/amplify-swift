// swiftlint:disable all
import Amplify
import Foundation

extension Blog6 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case posts
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let blog6 = Blog6.keys
    
    model.pluralName = "Blog6s"
    
    model.fields(
      .id(),
      .field(blog6.name, is: .required, ofType: .string),
      .hasMany(blog6.posts, is: .optional, ofType: Post6.self, associatedWith: Post6.keys.blog),
      .field(blog6.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(blog6.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}