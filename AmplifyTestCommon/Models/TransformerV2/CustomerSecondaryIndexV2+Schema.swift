//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension CustomerSecondaryIndexV2 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case name
    case phoneNumber
    case accountRepresentativeID
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let customerSecondaryIndexV2 = CustomerSecondaryIndexV2.keys

    model.pluralName = "CustomerSecondaryIndexV2s"

    model.attributes(
      .index(fields: ["accountRepresentativeID"], name: "byRepresentative")
    )

    model.fields(
      .id(),
      .field(customerSecondaryIndexV2.name, is: .required, ofType: .string),
      .field(customerSecondaryIndexV2.phoneNumber, is: .optional, ofType: .string),
      .field(customerSecondaryIndexV2.accountRepresentativeID, is: .required, ofType: .string),
      .field(customerSecondaryIndexV2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(customerSecondaryIndexV2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
