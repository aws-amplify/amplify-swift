// swiftlint:disable all
import Amplify
import Foundation

extension NestedTypeTestModel {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case nestedVal
    case nullableNestedVal
    case nestedList
    case nestedNullableList
    case nullableNestedList
    case nullableNestedNullableList
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let nestedTypeTestModel = NestedTypeTestModel.keys
    
    model.pluralName = "NestedTypeTestModels"
    
    model.fields(
      .id(),
      .field(nestedTypeTestModel.nestedVal, is: .required, ofType: .embedded(type: Nested.self)),
      .field(nestedTypeTestModel.nullableNestedVal, is: .optional, ofType: .embedded(type: Nested.self)),
      .field(nestedTypeTestModel.nestedList, is: .required, ofType: .embeddedCollection(of: Nested.self)),
      .field(nestedTypeTestModel.nestedNullableList, is: .optional, ofType: .embeddedCollection(of: Nested.self)),
      .field(nestedTypeTestModel.nullableNestedList, is: .required, ofType: .embeddedCollection(of: Nested.self)),
      .field(nestedTypeTestModel.nullableNestedNullableList, is: .optional, ofType: .embeddedCollection(of: Nested.self)),
      .field(nestedTypeTestModel.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(nestedTypeTestModel.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}