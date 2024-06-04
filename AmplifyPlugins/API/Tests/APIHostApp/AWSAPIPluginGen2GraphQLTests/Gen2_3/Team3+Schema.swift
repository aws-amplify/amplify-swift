// swiftlint:disable all
import Amplify
import Foundation

extension Team3 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case mantra
    case members
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let team3 = Team3.keys
    
    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Team3s"
    model.syncPluralName = "Team3s"
    
    model.attributes(
      .primaryKey(fields: [team3.id])
    )
    
    model.fields(
      .field(team3.id, is: .required, ofType: .string),
      .field(team3.mantra, is: .required, ofType: .string),
      .hasMany(team3.members, is: .optional, ofType: Member3.self, associatedFields: [Member3.keys.team]),
      .field(team3.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(team3.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Team3> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Team3: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Team3 {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var mantra: FieldPath<String>   {
      string("mantra") 
    }
  public var members: ModelPath<Member3>   {
      Member3.Path(name: "members", isCollection: true, parent: self) 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}
