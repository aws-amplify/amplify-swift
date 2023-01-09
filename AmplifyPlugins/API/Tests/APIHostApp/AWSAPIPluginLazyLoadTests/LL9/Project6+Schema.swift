// swiftlint:disable all
import Amplify
import Foundation

extension Project6 {
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
    let project6 = Project6.keys
    
    model.pluralName = "Project6s"
    
    model.attributes(
      .index(fields: ["projectId", "name"], name: nil),
      .primaryKey(fields: [project6.projectId, project6.name])
    )
    
    model.fields(
      .field(project6.projectId, is: .required, ofType: .string),
      .field(project6.name, is: .required, ofType: .string),
      .hasOne(project6.team, is: .optional, ofType: Team6.self, associatedWith: Team6.keys.teamId, targetNames: ["teamId", "teamName"]),
      .field(project6.teamId, is: .optional, ofType: .string),
      .field(project6.teamName, is: .optional, ofType: .string),
      .field(project6.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(project6.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Project6> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Project6: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension Project6.IdentifierProtocol {
  public static func identifier(projectId: String,
      name: String) -> Self {
    .make(fields:[(name: "projectId", value: projectId), (name: "name", value: name)])
  }
}
extension ModelPath where ModelType == Project6 {
  public var projectId: FieldPath<String>   {
      string("projectId")
    }
  public var name: FieldPath<String>   {
      string("name")
    }
  public var team: ModelPath<Team6>   {
      Team6.Path(name: "team", parent: self)
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
