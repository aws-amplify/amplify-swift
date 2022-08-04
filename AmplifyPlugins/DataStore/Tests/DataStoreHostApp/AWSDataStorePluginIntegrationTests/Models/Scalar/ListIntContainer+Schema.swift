//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension ListIntContainer {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case test
    case nullableInt
    case intList
    case intNullableList
    case nullableIntList
    case nullableIntNullableList
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let listIntContainer = ListIntContainer.keys

    model.listPluralName = "ListIntContainers"
    model.syncPluralName = "ListIntContainers"

    model.fields(
      .id(),
      .field(listIntContainer.test, is: .required, ofType: .int),
      .field(listIntContainer.nullableInt, is: .optional, ofType: .int),
      .field(listIntContainer.intList, is: .required, ofType: .embeddedCollection(of: Int.self)),
      .field(listIntContainer.intNullableList, is: .optional, ofType: .embeddedCollection(of: Int.self)),
      .field(listIntContainer.nullableIntList, is: .required, ofType: .embeddedCollection(of: Int.self)),
      .field(listIntContainer.nullableIntNullableList, is: .optional, ofType: .embeddedCollection(of: Int.self))
    )
    }
}
