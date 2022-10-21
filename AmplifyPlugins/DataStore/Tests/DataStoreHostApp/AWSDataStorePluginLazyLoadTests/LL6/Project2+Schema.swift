// swiftlint:disable all
import Amplify
import Foundation

extension Project2 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case projectId
    case name
    case team
    case createdAt
    case updatedAt
    case project2TeamTeamId
    case project2TeamName
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let project2 = Project2.keys
    
    model.pluralName = "Project2s"
    
    model.attributes(
      .index(fields: ["projectId", "name"], name: nil),
      .primaryKey(fields: [project2.projectId, project2.name])
    )
    
    model.fields(
      .field(project2.projectId, is: .required, ofType: .string),
      .field(project2.name, is: .required, ofType: .string),
      .hasOne(project2.team, is: .optional, ofType: Team2.self, associatedWith: Team2.keys.teamId, targetNames: ["project2TeamTeamId", "project2TeamName"]),
      .field(project2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(project2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(project2.project2TeamTeamId, is: .optional, ofType: .string),
      .field(project2.project2TeamName, is: .optional, ofType: .string)
    )
    }
}

extension Project2: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Project2.IdentifierProtocol {
  public static func identifier(projectId: String,
      name: String) -> Self {
    .make(fields:[(name: "projectId", value: projectId), (name: "name", value: name)])
  }
}