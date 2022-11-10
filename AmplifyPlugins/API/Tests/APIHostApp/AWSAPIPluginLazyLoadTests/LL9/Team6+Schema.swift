// swiftlint:disable all
import Amplify
import Foundation

extension Team6 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case teamId
    case name
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let team6 = Team6.keys
    
    model.pluralName = "Team6s"
    
    model.attributes(
      .index(fields: ["teamId", "name"], name: nil),
      .primaryKey(fields: [team6.teamId, team6.name])
    )
    
    model.fields(
      .field(team6.teamId, is: .required, ofType: .string),
      .field(team6.name, is: .required, ofType: .string),
      .field(team6.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(team6.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Team6: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Team6.IdentifierProtocol {
  public static func identifier(teamId: String,
      name: String) -> Self {
    .make(fields:[(name: "teamId", value: teamId), (name: "name", value: name)])
  }
}