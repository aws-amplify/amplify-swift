//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Comment3aV2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case createdAt
    case updatedAt
    case post3aV2CommentsId
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let comment3aV2 = Comment3aV2.keys

    model.pluralName = "Comment3aV2s"

    model.fields(
      .id(),
      .field(comment3aV2.content, is: .required, ofType: .string),
      .field(comment3aV2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment3aV2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment3aV2.post3aV2CommentsId, is: .optional, ofType: .string)
    )
    }
}
