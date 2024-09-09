//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension SchemaDrift {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case enumValue
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let schemaDrift = SchemaDrift.keys

    model.pluralName = "SchemaDrifts"

    model.fields(
      .id(),
      .field(schemaDrift.enumValue, is: .optional, ofType: .enum(type: EnumDrift.self)),
      .field(schemaDrift.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(schemaDrift.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
