//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

@preconcurrency import Amplify

// swiftlint:disable all
import Foundation

public extension Record {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case name
    case description
    case coverId
    case cover
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
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
            targetName: "coverId"
        ),
        .field(record.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
        .field(record.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

