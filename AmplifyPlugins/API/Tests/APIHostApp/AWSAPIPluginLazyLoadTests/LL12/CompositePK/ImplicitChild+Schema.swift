// swiftlint:disable all
import Amplify
import Foundation

extension ImplicitChild {
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
    let implicitChild = ImplicitChild.keys
    
    model.pluralName = "ImplicitChildren"
    
    model.attributes(
      .index(fields: ["childId", "content"], name: nil),
      .primaryKey(fields: [implicitChild.childId, implicitChild.content])
    )
    
    model.fields(
      .field(implicitChild.childId, is: .required, ofType: .string),
      .field(implicitChild.content, is: .required, ofType: .string),
      .belongsTo(implicitChild.parent, is: .required, ofType: CompositePKParent.self, targetNames: ["compositePKParentImplicitChildrenCustomId", "compositePKParentImplicitChildrenContent"]),
      .field(implicitChild.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(implicitChild.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<ImplicitChild> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension ImplicitChild: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension ImplicitChild.IdentifierProtocol {
  public static func identifier(childId: String,
      content: String) -> Self {
    .make(fields:[(name: "childId", value: childId), (name: "content", value: content)])
  }
}
extension ModelPath where ModelType == ImplicitChild {
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