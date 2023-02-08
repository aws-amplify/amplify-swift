// swiftlint:disable all
import Amplify
import Foundation

extension Project1 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case projectId
    case name
    case team
    case createdAt
    case updatedAt
    case project1TeamTeamId
    case project1TeamName
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema
  
  public static let schema = defineSchema { model in
    let project1 = Project1.keys
    
    model.pluralName = "Project1s"
    
    model.attributes(
      .index(fields: ["projectId", "name"], name: nil),
      .primaryKey(fields: [project1.projectId, project1.name])
    )
    
    model.fields(
      .field(project1.projectId, is: .required, ofType: .string),
      .field(project1.name, is: .required, ofType: .string),
      .hasOne(project1.team, is: .optional, ofType: Team1.self, associatedWith: Team1.keys.project, targetNames: ["project1TeamTeamId", "project1TeamName"]),
      .field(project1.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(project1.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(project1.project1TeamTeamId, is: .optional, ofType: .string),
      .field(project1.project1TeamName, is: .optional, ofType: .string)
    )
    }
    public class Path: ModelPath<Project1> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Project1: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Project1.IdentifierProtocol {
  public static func identifier(projectId: String,
      name: String) -> Self {
    .make(fields:[(name: "projectId", value: projectId), (name: "name", value: name)])
  }
}
extension ModelPath where ModelType == Project1 {
  public var projectId: FieldPath<String>   {
      string("projectId")
    }
  public var name: FieldPath<String>   {
      string("name")
    }
  public var team: ModelPath<Team1>   {
      Team1.Path(name: "team", parent: self)
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
  public var project1TeamTeamId: FieldPath<String>   {
      string("project1TeamTeamId")
    }
  public var project1TeamName: FieldPath<String>   {
      string("project1TeamName")
    }
}
