// swiftlint:disable all
import Amplify
import Foundation

extension Team5 {
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
    let team5 = Team5.keys
    
    model.pluralName = "Team5s"
    
    model.attributes(
      .index(fields: ["teamId", "name"], name: nil),
      .primaryKey(fields: [team5.teamId, team5.name])
    )
    
    model.fields(
      .field(team5.teamId, is: .required, ofType: .string),
      .field(team5.name, is: .required, ofType: .string),
      .belongsTo(team5.project, is: .optional, ofType: Project5.self, targetNames: ["projectId", "projectName"]),
      .field(team5.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(team5.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Team5> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Team5: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Team5.IdentifierProtocol {
  public static func identifier(teamId: String,
      name: String) -> Self {
    .make(fields:[(name: "teamId", value: teamId), (name: "name", value: name)])
  }
}
extension ModelPath where ModelType == Team5 {
  public var teamId: FieldPath<String>   {
      string("teamId")
    }
  public var name: FieldPath<String>   {
      string("name")
    }
  public var project: ModelPath<Project5>   {
      Project5.Path(name: "project", parent: self)
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
