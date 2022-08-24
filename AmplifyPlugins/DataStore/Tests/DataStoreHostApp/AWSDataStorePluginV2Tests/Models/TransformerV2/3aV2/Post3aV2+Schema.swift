//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Post3aV2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case comments
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let post3aV2 = Post3aV2.keys

    model.pluralName = "Post3aV2s"

    model.fields(
      .id(),
      .field(post3aV2.title, is: .required, ofType: .string),
      .hasMany(post3aV2.comments, is: .optional, ofType: Comment3aV2.self, associatedWith: Comment3aV2.keys.post3aV2CommentsId),
      .field(post3aV2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post3aV2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
