// swiftlint:disable all
import Amplify
import Foundation

extension StrangeExplicitChild {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case strangeId
    case content
    case parent
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let strangeExplicitChild = StrangeExplicitChild.keys
    
    model.pluralName = "StrangeExplicitChildren"
    
    model.attributes(
      .index(fields: ["strangeId", "content"], name: nil),
      .index(fields: ["strangeParentId", "strangeParentTitle"], name: "byCompositePKParentX"),
      .primaryKey(fields: [strangeExplicitChild.strangeId, strangeExplicitChild.content])
    )
    
    model.fields(
      .field(strangeExplicitChild.strangeId, is: .required, ofType: .string),
      .field(strangeExplicitChild.content, is: .required, ofType: .string),
      .belongsTo(strangeExplicitChild.parent, is: .required, ofType: CompositePKParent.self, targetNames: ["strangeParentId", "strangeParentTitle"]),
      .field(strangeExplicitChild.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(strangeExplicitChild.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<StrangeExplicitChild> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension StrangeExplicitChild: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension StrangeExplicitChild.IdentifierProtocol {
  public static func identifier(strangeId: String,
      content: String) -> Self {
    .make(fields:[(name: "strangeId", value: strangeId), (name: "content", value: content)])
  }
}
extension ModelPath where ModelType == StrangeExplicitChild {
  public var strangeId: FieldPath<String>   {
      string("strangeId") 
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
