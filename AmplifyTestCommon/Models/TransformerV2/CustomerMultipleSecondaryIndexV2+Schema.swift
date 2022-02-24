//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension CustomerMultipleSecondaryIndexV2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case phoneNumber
    case age
    case accountRepresentativeID
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let customerMultipleSecondaryIndexV2 = CustomerMultipleSecondaryIndexV2.keys

    model.pluralName = "CustomerMultipleSecondaryIndexV2s"

    model.attributes(
      .index(fields: ["name", "phoneNumber"], name: "byNameAndPhoneNumber"),
      .index(fields: ["age", "phoneNumber"], name: "byAgeAndPhoneNumber"),
      .index(fields: ["accountRepresentativeID"], name: "byRepresentative")
    )

    model.fields(
      .id(),
      .field(customerMultipleSecondaryIndexV2.name, is: .required, ofType: .string),
      .field(customerMultipleSecondaryIndexV2.phoneNumber, is: .optional, ofType: .string),
      .field(customerMultipleSecondaryIndexV2.age, is: .required, ofType: .int),
      .field(customerMultipleSecondaryIndexV2.accountRepresentativeID, is: .required, ofType: .string),
      .field(customerMultipleSecondaryIndexV2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(customerMultipleSecondaryIndexV2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
