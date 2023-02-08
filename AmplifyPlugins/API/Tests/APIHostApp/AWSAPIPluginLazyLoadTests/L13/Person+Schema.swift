// swiftlint:disable all
import Amplify
import Foundation

extension Person {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case callerOf
    case calleeOf
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema
  
  public static let schema = defineSchema { model in
    let person = Person.keys
    
    model.pluralName = "People"
    
    model.attributes(
      .primaryKey(fields: [person.id])
    )
    
    model.fields(
      .field(person.id, is: .required, ofType: .string),
      .field(person.name, is: .required, ofType: .string),
      .hasMany(person.callerOf, is: .optional, ofType: PhoneCall.self, associatedWith: PhoneCall.keys.caller),
      // TODO: Below `associatedWith` was incorrectly generated as `PhoneCall.keys.caller`, it was manually
      // modified to `PhoneCall.keys.caller`
      .hasMany(person.calleeOf, is: .optional, ofType: PhoneCall.self, associatedWith: PhoneCall.keys.callee),
      .field(person.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(person.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Person> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Person: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Person {
  public var id: FieldPath<String>   {
      string("id")
    }
  public var name: FieldPath<String>   {
      string("name")
    }
  public var callerOf: ModelPath<PhoneCall>   {
      PhoneCall.Path(name: "callerOf", isCollection: true, parent: self)
    }
  public var calleeOf: ModelPath<PhoneCall>   {
      PhoneCall.Path(name: "calleeOf", isCollection: true, parent: self)
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
