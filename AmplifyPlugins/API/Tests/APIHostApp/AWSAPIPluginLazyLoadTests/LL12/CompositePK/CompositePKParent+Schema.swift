// swiftlint:disable all
import Amplify
import Foundation

extension CompositePKParent {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case customId
    case content
    case children
    case implicitChildren
    case strangeChildren
    case childrenSansBelongsTo
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let compositePKParent = CompositePKParent.keys
    
    model.pluralName = "CompositePKParents"
    
    model.attributes(
      .index(fields: ["customId", "content"], name: nil),
      .primaryKey(fields: [compositePKParent.customId, compositePKParent.content])
    )
    
    model.fields(
      .field(compositePKParent.customId, is: .required, ofType: .string),
      .field(compositePKParent.content, is: .required, ofType: .string),
      .hasMany(compositePKParent.children, is: .optional, ofType: CompositePKChild.self, associatedWith: CompositePKChild.keys.parent),
      .hasMany(compositePKParent.implicitChildren, is: .optional, ofType: ImplicitChild.self, associatedWith: ImplicitChild.keys.parent),
      .hasMany(compositePKParent.strangeChildren, is: .optional, ofType: StrangeExplicitChild.self, associatedWith: StrangeExplicitChild.keys.parent),
      .hasMany(compositePKParent.childrenSansBelongsTo, is: .optional, ofType: ChildSansBelongsTo.self, associatedWith: ChildSansBelongsTo.keys.compositePKParentChildrenSansBelongsToCustomId),
      .field(compositePKParent.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(compositePKParent.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<CompositePKParent> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension CompositePKParent: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension CompositePKParent.IdentifierProtocol {
  public static func identifier(customId: String,
      content: String) -> Self {
    .make(fields:[(name: "customId", value: customId), (name: "content", value: content)])
  }
}
extension ModelPath where ModelType == CompositePKParent {
  public var customId: FieldPath<String>   {
      string("customId") 
    }
  public var content: FieldPath<String>   {
      string("content") 
    }
  public var children: ModelPath<CompositePKChild>   {
      CompositePKChild.Path(name: "children", isCollection: true, parent: self) 
    }
  public var implicitChildren: ModelPath<ImplicitChild>   {
      ImplicitChild.Path(name: "implicitChildren", isCollection: true, parent: self) 
    }
  public var strangeChildren: ModelPath<StrangeExplicitChild>   {
      StrangeExplicitChild.Path(name: "strangeChildren", isCollection: true, parent: self) 
    }
  public var childrenSansBelongsTo: ModelPath<ChildSansBelongsTo>   {
      ChildSansBelongsTo.Path(name: "childrenSansBelongsTo", isCollection: true, parent: self) 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}