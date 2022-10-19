// swiftlint:disable all
import Amplify
import Foundation

extension Team1 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case teamId
    case name
    case project
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let team1 = Team1.keys
    
    model.pluralName = "Team1s"
    
    model.attributes(
      .index(fields: ["teamId", "name"], name: nil),
      .primaryKey(fields: [team1.teamId, team1.name])
    )
    
    model.fields(
      .field(team1.teamId, is: .required, ofType: .string),
      .field(team1.name, is: .required, ofType: .string),
      .belongsTo(team1.project, is: .optional, ofType: Project1.self, targetNames: ["team1ProjectProjectId", "team1ProjectName"]),
      .field(team1.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(team1.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Team1: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Team1.IdentifierProtocol {
  public static func identifier(teamId: String,
      name: String) -> Self {
    .make(fields:[(name: "teamId", value: teamId), (name: "name", value: name)])
  }
}