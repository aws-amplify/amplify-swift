// swiftlint:disable all
import Amplify
import Foundation

extension ModelExplicitDefaultPk {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let modelExplicitDefaultPk = ModelExplicitDefaultPk.keys
    
    model.pluralName = "ModelExplicitDefaultPks"
    
    model.attributes(
      .index(fields: ["id"], name: nil),
      .primaryKey(fields: [modelExplicitDefaultPk.id])
    )
    
    model.fields(
      .field(modelExplicitDefaultPk.id, is: .required, ofType: .string),
      .field(modelExplicitDefaultPk.name, is: .optional, ofType: .string),
      .field(modelExplicitDefaultPk.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(modelExplicitDefaultPk.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension ModelExplicitDefaultPk: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}