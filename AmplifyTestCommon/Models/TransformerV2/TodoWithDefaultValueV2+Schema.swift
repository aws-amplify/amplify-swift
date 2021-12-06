//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension TodoWithDefaultValueV2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let todoWithDefaultValueV2 = TodoWithDefaultValueV2.keys

    model.pluralName = "TodoWithDefaultValueV2s"

    model.fields(
      .id(),
      .field(todoWithDefaultValueV2.content, is: .optional, ofType: .string),
      .field(todoWithDefaultValueV2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todoWithDefaultValueV2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
