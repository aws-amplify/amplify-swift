//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension TodoCustomTimestampV2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case createdOn
    case updatedOn
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let todoCustomTimestampV2 = TodoCustomTimestampV2.keys

    model.pluralName = "TodoCustomTimestampV2s"

    model.fields(
      .id(),
      .field(todoCustomTimestampV2.content, is: .optional, ofType: .string),
      .field(todoCustomTimestampV2.createdOn, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todoCustomTimestampV2.updatedOn, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
