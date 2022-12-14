// swiftlint:disable all
import Amplify
import Foundation

extension Project5 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case projectId
    case name
    case team
    case teamId
    case teamName
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema
  
  public static let schema = defineSchema { model in
    let project5 = Project5.keys
    
    model.pluralName = "Project5s"
    
    model.attributes(
      .index(fields: ["projectId", "name"], name: nil),
      .primaryKey(fields: [project5.projectId, project5.name])
    )
    
    model.fields(
      .field(project5.projectId, is: .required, ofType: .string),
      .field(project5.name, is: .required, ofType: .string),
      .hasOne(project5.team, is: .optional, ofType: Team5.self, associatedWith: Team5.keys.project, targetNames: ["teamId", "teamName"]),
      .field(project5.teamId, is: .optional, ofType: .string),
      .field(project5.teamName, is: .optional, ofType: .string),
      .field(project5.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(project5.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Project5> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Project5: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Project5.IdentifierProtocol {
  public static func identifier(projectId: String,
      name: String) -> Self {
    .make(fields:[(name: "projectId", value: projectId), (name: "name", value: name)])
  }
}
extension ModelPath where ModelType == Project5 {
  public var projectId: FieldPath<String>   {
      string("projectId")
    }
  public var name: FieldPath<String>   {
      string("name")
    }
  public var team: ModelPath<Team5>   {
      Team5.Path(name: "team", parent: self)
    }
  public var teamId: FieldPath<String>   {
      string("teamId")
    }
  public var teamName: FieldPath<String>   {
      string("teamName")
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
