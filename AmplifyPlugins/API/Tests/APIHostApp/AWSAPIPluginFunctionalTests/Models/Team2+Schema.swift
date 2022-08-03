// swiftlint:disable all
import Amplify
import Foundation

extension Team2 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let team2 = Team2.keys
    
    model.pluralName = "Team2s"
    
    model.fields(
      .id(),
      .field(team2.name, is: .required, ofType: .string),
      .field(team2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(team2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}