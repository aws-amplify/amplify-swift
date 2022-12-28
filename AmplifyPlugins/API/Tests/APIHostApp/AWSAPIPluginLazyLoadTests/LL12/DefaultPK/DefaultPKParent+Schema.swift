// swiftlint:disable all
import Amplify
import Foundation

extension DefaultPKParent {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case children
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let defaultPKParent = DefaultPKParent.keys
    
    model.pluralName = "DefaultPKParents"
    
    model.attributes(
      .index(fields: ["id"], name: nil),
      .primaryKey(fields: [defaultPKParent.id])
    )
    
    model.fields(
      .field(defaultPKParent.id, is: .required, ofType: .string),
      .field(defaultPKParent.content, is: .optional, ofType: .string),
      .hasMany(defaultPKParent.children, is: .optional, ofType: DefaultPKChild.self, associatedWith: DefaultPKChild.keys.parent),
      .field(defaultPKParent.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(defaultPKParent.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<DefaultPKParent> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension DefaultPKParent: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == DefaultPKParent {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var content: FieldPath<String>   {
      string("content") 
    }
  public var children: ModelPath<DefaultPKChild>   {
      DefaultPKChild.Path(name: "children", isCollection: true, parent: self) 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}