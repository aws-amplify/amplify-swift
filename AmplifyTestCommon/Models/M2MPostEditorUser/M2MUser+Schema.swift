// swiftlint:disable all
import Amplify
import Foundation

extension M2MUser {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case username
    case posts
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let m2MUser = M2MUser.keys
    
    model.pluralName = "M2MUsers"
    
    model.fields(
      .id(),
      .field(m2MUser.username, is: .required, ofType: .string),
      .hasMany(m2MUser.posts, is: .optional, ofType: M2MPostEditor.self, associatedWith: M2MPostEditor.keys.editor)
    )
    }
}