// swiftlint:disable all
import Amplify
import Foundation

extension M2MPostEditor {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case post
    case editor
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let m2MPostEditor = M2MPostEditor.keys
    
    model.pluralName = "M2MPostEditors"
    
    model.fields(
      .id(),
      .belongsTo(m2MPostEditor.post, is: .required, ofType: M2MPost.self, targetName: "postID"),
      .belongsTo(m2MPostEditor.editor, is: .required, ofType: M2MUser.self, targetName: "editorID")
    )
    }
}