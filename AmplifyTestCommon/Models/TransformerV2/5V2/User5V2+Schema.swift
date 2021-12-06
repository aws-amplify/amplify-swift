//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension User5V2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case username
    case posts
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let user5V2 = User5V2.keys

    model.pluralName = "User5V2s"

    model.fields(
      .id(),
      .field(user5V2.username, is: .required, ofType: .string),
      .hasMany(user5V2.posts, is: .optional, ofType: PostEditor5V2.self, associatedWith: PostEditor5V2.keys.user5V2),
      .field(user5V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(user5V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
