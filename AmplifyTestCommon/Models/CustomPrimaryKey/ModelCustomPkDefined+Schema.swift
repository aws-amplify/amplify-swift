//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension ModelCustomPkDefined {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case dob
    case name
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let modelCompositePk = ModelCustomPkDefined.keys

    model.pluralName = "ModelCustomPkDefined"

    model.attributes(
        .primaryKey(fields: [modelCompositePk.id, modelCompositePk.dob]),
        .index(fields: ["dob"], name: "byDob"),
        .index(fields: ["name"], name: "byName")
    )

    model.fields(
        .field(modelCompositePk.id, is: .required, ofType: .string),
        .field(modelCompositePk.dob, is: .required, ofType: .dateTime),
        .field(modelCompositePk.name, is: .optional, ofType: .string),
        .field(modelCompositePk.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
        .field(modelCompositePk.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
