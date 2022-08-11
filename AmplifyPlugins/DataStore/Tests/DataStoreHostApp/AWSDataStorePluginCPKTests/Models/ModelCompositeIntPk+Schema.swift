// swiftlint:disable all
import Amplify
import Foundation

extension ModelCompositeIntPk {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case serial
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let modelCompositeIntPk = ModelCompositeIntPk.keys
    
    model.pluralName = "ModelCompositeIntPks"
    
    model.attributes(
      .index(fields: ["id", "serial"], name: nil),
      .primaryKey(fields: [modelCompositeIntPk.id, modelCompositeIntPk.serial])
    )
    
    model.fields(
      .field(modelCompositeIntPk.id, is: .required, ofType: .string),
      .field(modelCompositeIntPk.serial, is: .required, ofType: .int),
      .field(modelCompositeIntPk.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(modelCompositeIntPk.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension ModelCompositeIntPk: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension ModelCompositeIntPk.IdentifierProtocol {
  public static func identifier(id: String,
      serial: Int) -> Self {
    .make(fields:[(name: "id", value: id), (name: "serial", value: serial)])
  }
}