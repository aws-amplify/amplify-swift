//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension ModelCompositePk {
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
    let modelCompositePk = ModelCompositePk.keys

    model.pluralName = "ModelCompositePks"

    model.attributes(
      .index(fields: ["id", "dob"], name: nil)
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

extension ModelCompositePk: ModelIdentifiable {
    public typealias IdentifierFormat = ModelIdentifierFormat.Custom
    public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension ModelCompositePk.IdentifierProtocol {
    public static func identifier(id: String, dob: Temporal.DateTime) -> Self {
        .make(fields: [(name: "id", value: id), (name: "dob", value: dob)])
    }
}

