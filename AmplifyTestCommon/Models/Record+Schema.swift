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
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let record = Record.keys

    model.pluralName = "Records"

    model.fields(
        .id(),
        .field(record.name, is: .required, ofType: .string),
        .field(record.description, is: .optional, ofType: .string),
        .field(record.createdAt, is: .optional, access: .readOnly, ofType: .date),
        .field(record.updatedAt, is: .optional, access: .readOnly, ofType: .date)
        )
    }
}

