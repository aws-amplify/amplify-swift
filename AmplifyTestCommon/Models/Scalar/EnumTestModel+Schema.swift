//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension EnumTestModel {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case enumVal
    case nullableEnumVal
    case enumList
    case enumNullableList
    case nullableEnumList
    case nullableEnumNullableList
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let enumTestModel = EnumTestModel.keys

    model.listPluralName = "EnumTestModels"
    model.syncPluralName = "EnumTestModels"

    model.fields(
      .id(),
      .field(enumTestModel.enumVal, is: .required, ofType: .enum(type: TestEnum.self)),
      .field(enumTestModel.nullableEnumVal, is: .optional, ofType: .enum(type: TestEnum.self)),
      .field(enumTestModel.enumList, is: .required, ofType: .embeddedCollection(of: TestEnum.self)),
      .field(enumTestModel.enumNullableList, is: .optional, ofType: .embeddedCollection(of: TestEnum.self)),
      .field(enumTestModel.nullableEnumList, is: .required, ofType: .embeddedCollection(of: TestEnum.self)),
      .field(enumTestModel.nullableEnumNullableList, is: .optional, ofType: .embeddedCollection(of: TestEnum.self))
    )
    }
}
