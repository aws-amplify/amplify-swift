// swiftlint:disable all
import Amplify
import Foundation

extension DefaultPKChild {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case parent
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let defaultPKChild = DefaultPKChild.keys
    
    model.pluralName = "DefaultPKChildren"
    
    model.attributes(
      .index(fields: ["id"], name: nil),
      .primaryKey(fields: [defaultPKChild.id])
    )
    
    model.fields(
      .field(defaultPKChild.id, is: .required, ofType: .string),
      .field(defaultPKChild.content, is: .optional, ofType: .string),
      .belongsTo(defaultPKChild.parent, is: .optional, ofType: DefaultPKParent.self, targetNames: ["defaultPKParentChildrenId"]),
      .field(defaultPKChild.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(defaultPKChild.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<DefaultPKChild> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension DefaultPKChild: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == DefaultPKChild {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var content: FieldPath<String>   {
      string("content") 
    }
  public var parent: ModelPath<DefaultPKParent>   {
      DefaultPKParent.Path(name: "parent", parent: self) 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}