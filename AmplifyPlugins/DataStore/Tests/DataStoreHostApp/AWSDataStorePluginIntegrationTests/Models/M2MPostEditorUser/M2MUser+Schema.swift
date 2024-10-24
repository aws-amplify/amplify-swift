//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension M2MUser {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case username
    case posts
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let m2MUser = M2MUser.keys

    model.listPluralName = "M2MUsers"
    model.syncPluralName = "M2MUsers"

    model.fields(
      .id(),
      .field(m2MUser.username, is: .required, ofType: .string),
      .hasMany(m2MUser.posts, is: .optional, ofType: M2MPostEditor.self, associatedWith: M2MPostEditor.keys.editor)
    )
    }
}
