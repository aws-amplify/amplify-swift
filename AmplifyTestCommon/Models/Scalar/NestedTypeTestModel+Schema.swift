//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension NestedTypeTestModel {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case nestedVal
    case nullableNestedVal
    case nestedList
    case nestedNullableList
    case nullableNestedList
    case nullableNestedNullableList
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let nestedTypeTestModel = NestedTypeTestModel.keys

    model.listPluralName = "NestedTypeTestModels"
    model.syncPluralName = "NestedTypeTestModels"

    model.fields(
      .id(),
      .field(nestedTypeTestModel.nestedVal, is: .required, ofType: .embedded(type: Nested.self)),
      .field(nestedTypeTestModel.nullableNestedVal, is: .optional, ofType: .embedded(type: Nested.self)),
      .field(nestedTypeTestModel.nestedList, is: .required, ofType: .embeddedCollection(of: Nested.self)),
      .field(nestedTypeTestModel.nestedNullableList, is: .optional, ofType: .embeddedCollection(of: Nested.self)),
      .field(nestedTypeTestModel.nullableNestedList, is: .required, ofType: .embeddedCollection(of: Nested.self)),
      .field(nestedTypeTestModel.nullableNestedNullableList, is: .optional, ofType: .embeddedCollection(of: Nested.self))
    )
    }
}
