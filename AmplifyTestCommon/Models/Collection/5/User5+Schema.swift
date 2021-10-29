//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension User5 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case username
    case posts
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let user5 = User5.keys

    model.listPluralName = "User5s"
    model.syncPluralName = "User5s"

    model.fields(
      .id(),
      .field(user5.username, is: .required, ofType: .string),
      .hasMany(user5.posts, is: .optional, ofType: PostEditor5.self, associatedWith: PostEditor5.keys.editor)
    )
    }
}
