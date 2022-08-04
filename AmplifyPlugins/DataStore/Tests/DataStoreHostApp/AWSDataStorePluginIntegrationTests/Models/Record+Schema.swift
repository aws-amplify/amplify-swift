//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Foundation
import Amplify

extension Record {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case description
    case coverId
    case cover
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let record = Record.keys

    model.listPluralName = "Records"
    model.listPluralName = "Records"

    model.fields(
        .id(),
        .field(record.name, is: .required, ofType: .string),
        .field(record.description, is: .optional, ofType: .string),
        .field(record.coverId, is: .optional, isReadOnly: true, ofType: .string),
        .hasOne(
            record.cover,
            is: .optional,
            isReadOnly: true,
            ofType: RecordCover.self,
            associatedWith: RecordCover.keys.id,
            targetName: "coverId"),
        .field(record.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
        .field(record.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
        )
    }
}

