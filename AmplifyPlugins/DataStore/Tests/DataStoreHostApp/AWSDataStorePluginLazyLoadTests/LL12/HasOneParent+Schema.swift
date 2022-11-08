// swiftlint:disable all
import Amplify
import Foundation

extension HasOneParent {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case child
    case createdAt
    case updatedAt
    case hasOneParentChildId
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let hasOneParent = HasOneParent.keys
    
    model.pluralName = "HasOneParents"
    
    model.attributes(
      .index(fields: ["id"], name: nil),
      .primaryKey(fields: [hasOneParent.id])
    )
    
    model.fields(
      .field(hasOneParent.id, is: .required, ofType: .string),
      .hasOne(hasOneParent.child, is: .optional, ofType: HasOneChild.self, associatedWith: HasOneChild.keys.id, targetNames: ["hasOneParentChildId"]),
      .field(hasOneParent.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(hasOneParent.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(hasOneParent.hasOneParentChildId, is: .optional, ofType: .string)
    )
    }
}

extension HasOneParent: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}