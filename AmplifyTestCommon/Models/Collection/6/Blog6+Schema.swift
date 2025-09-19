//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension Blog6 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case name
    case posts
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let blog6 = Blog6.keys

    model.listPluralName = "Blog6s"
    model.syncPluralName = "Blog6s"

    model.fields(
      .id(),
      .field(blog6.name, is: .required, ofType: .string),
      .hasMany(blog6.posts, is: .optional, ofType: Post6.self, associatedWith: Post6.keys.blog)
    )
    }
}
