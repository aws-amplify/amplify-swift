// swiftlint:disable all
import Amplify
import Foundation

extension MyNestedModel8 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case nestedName
    case notes
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let myNestedModel8 = MyNestedModel8.keys
    
    model.pluralName = "MyNestedModel8s"
    
    model.fields(
      .field(myNestedModel8.id, is: .required, ofType: .string),
      .field(myNestedModel8.nestedName, is: .required, ofType: .string),
      .field(myNestedModel8.notes, is: .optional, ofType: .embeddedCollection(of: String.self))
    )
    }
}