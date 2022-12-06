// swiftlint:disable all
import Amplify
import Foundation

extension CompositePKChild {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case childId
    case content
    case parent
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let compositePKChild = CompositePKChild.keys
    
    model.pluralName = "CompositePKChildren"
    
    model.attributes(
      .index(fields: ["childId", "content"], name: nil),
      .index(fields: ["parentId", "parentTitle"], name: "byParent"),
      .primaryKey(fields: [compositePKChild.childId, compositePKChild.content])
    )
    
    model.fields(
      .field(compositePKChild.childId, is: .required, ofType: .string),
      .field(compositePKChild.content, is: .required, ofType: .string),
      .belongsTo(compositePKChild.parent, is: .optional, ofType: CompositePKParent.self, targetNames: ["parentId", "parentTitle"]),
      .field(compositePKChild.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(compositePKChild.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<CompositePKChild> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension CompositePKChild: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension CompositePKChild.IdentifierProtocol {
  public static func identifier(childId: String,
      content: String) -> Self {
    .make(fields:[(name: "childId", value: childId), (name: "content", value: content)])
  }
}
extension ModelPath where ModelType == CompositePKChild {
  public var childId: FieldPath<String>   {
      string("childId") 
    }
  public var content: FieldPath<String>   {
      string("content") 
    }
  public var parent: ModelPath<CompositePKParent>   {
      CompositePKParent.Path(name: "parent", parent: self) 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}