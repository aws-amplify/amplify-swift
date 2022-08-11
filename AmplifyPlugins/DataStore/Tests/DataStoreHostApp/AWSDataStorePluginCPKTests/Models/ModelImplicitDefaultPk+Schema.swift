// swiftlint:disable all
import Amplify
import Foundation

extension ModelImplicitDefaultPk {
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
    let modelImplicitDefaultPk = ModelImplicitDefaultPk.keys
    
    model.pluralName = "ModelImplicitDefaultPks"
    
    model.attributes(
      .primaryKey(fields: [modelImplicitDefaultPk.id])
    )
    
    model.fields(
      .field(modelImplicitDefaultPk.id, is: .required, ofType: .string),
      .field(modelImplicitDefaultPk.name, is: .optional, ofType: .string),
      .field(modelImplicitDefaultPk.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(modelImplicitDefaultPk.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension ModelImplicitDefaultPk: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}