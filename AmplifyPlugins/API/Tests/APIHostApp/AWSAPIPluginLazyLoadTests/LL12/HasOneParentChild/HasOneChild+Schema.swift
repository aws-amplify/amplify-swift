// swiftlint:disable all
import Amplify
import Foundation

extension HasOneChild {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let hasOneChild = HasOneChild.keys
    
    model.pluralName = "HasOneChildren"
    
    model.attributes(
      .index(fields: ["id"], name: nil),
      .primaryKey(fields: [hasOneChild.id])
    )
    
    model.fields(
      .field(hasOneChild.id, is: .required, ofType: .string),
      .field(hasOneChild.content, is: .optional, ofType: .string),
      .field(hasOneChild.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(hasOneChild.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<HasOneChild> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension HasOneChild: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == HasOneChild {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var content: FieldPath<String>   {
      string("content") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}