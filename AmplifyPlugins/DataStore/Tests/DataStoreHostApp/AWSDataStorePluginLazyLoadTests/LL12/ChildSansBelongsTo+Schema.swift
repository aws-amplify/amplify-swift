// swiftlint:disable all
import Amplify
import Foundation

extension ChildSansBelongsTo {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case childId
    case content
    case compositePKParentChildrenSansBelongsToCustomId
    case compositePKParentChildrenSansBelongsToContent
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let childSansBelongsTo = ChildSansBelongsTo.keys
    
    model.pluralName = "ChildSansBelongsTos"
    
    model.attributes(
      .index(fields: ["childId", "content"], name: nil),
      .index(fields: ["compositePKParentChildrenSansBelongsToCustomId", "compositePKParentChildrenSansBelongsToContent"], name: "byParent"),
      .primaryKey(fields: [childSansBelongsTo.childId, childSansBelongsTo.content])
    )
    
    model.fields(
      .field(childSansBelongsTo.childId, is: .required, ofType: .string),
      .field(childSansBelongsTo.content, is: .required, ofType: .string),
      .field(childSansBelongsTo.compositePKParentChildrenSansBelongsToCustomId, is: .required, ofType: .string),
      .field(childSansBelongsTo.compositePKParentChildrenSansBelongsToContent, is: .optional, ofType: .string),
      .field(childSansBelongsTo.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(childSansBelongsTo.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension ChildSansBelongsTo: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension ChildSansBelongsTo.IdentifierProtocol {
  public static func identifier(childId: String,
      content: String) -> Self {
    .make(fields:[(name: "childId", value: childId), (name: "content", value: content)])
  }
}