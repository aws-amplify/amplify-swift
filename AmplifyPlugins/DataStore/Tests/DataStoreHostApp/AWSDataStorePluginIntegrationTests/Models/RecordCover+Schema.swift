//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

// swiftlint:disable all
import Foundation

public extension RecordCover {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case artist
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let recordCover = RecordCover.keys

    model.listPluralName = "RecordCovers"
    model.syncPluralName = "RecordCovers"

    model.fields(
      .id(),
      .field(recordCover.artist, is: .required, ofType: .string),
      .field(recordCover.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(recordCover.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
