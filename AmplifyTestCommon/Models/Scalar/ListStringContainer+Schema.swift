//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension ListStringContainer {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case test
    case nullableString
    case stringList
    case stringNullableList
    case nullableStringList
    case nullableStringNullableList
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let listStringContainer = ListStringContainer.keys

    model.listPluralName = "ListStringContainers"
    model.syncPluralName = "ListStringContainers"

    model.fields(
      .id(),
      .field(listStringContainer.test, is: .required, ofType: .string),
      .field(listStringContainer.nullableString, is: .optional, ofType: .string),
      .field(listStringContainer.stringList, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(listStringContainer.stringNullableList, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(listStringContainer.nullableStringList, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(listStringContainer.nullableStringNullableList, is: .optional, ofType: .embeddedCollection(of: String.self))
    )
    }
}
