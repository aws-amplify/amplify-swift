// swiftlint:disable all
import Amplify
import Foundation

extension Team2 {
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
    let team2 = Team2.keys
    
    model.pluralName = "Team2s"
    
    model.attributes(
      .index(fields: ["teamId", "name"], name: nil),
      .primaryKey(fields: [team2.teamId, team2.name])
    )
    
    model.fields(
      .field(team2.teamId, is: .required, ofType: .string),
      .field(team2.name, is: .required, ofType: .string),
      .field(team2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(team2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    
    public class Path: ModelPath<Team2> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Team2: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Team2.IdentifierProtocol {
  public static func identifier(teamId: String,
      name: String) -> Self {
    .make(fields:[(name: "teamId", value: teamId), (name: "name", value: name)])
  }
}

extension ModelPath where ModelType == Team2 {
    var teamId: FieldPath<String> { string("teamId") }
    var name: FieldPath<String> { string("name") }
    var createdAt: FieldPath<Temporal.DateTime> { datetime("createdAt") }
    var updatedAt: FieldPath<Temporal.DateTime> { datetime("updatedAt") }
}
