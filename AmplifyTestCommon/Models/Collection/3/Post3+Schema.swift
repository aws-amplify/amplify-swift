//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension Post3 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case title
    case comments
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let post3 = Post3.keys

    model.listPluralName = "Post3s"
    model.syncPluralName = "Post3s"

    model.fields(
      .id(),
      .field(post3.title, is: .required, ofType: .string),
      .hasMany(post3.comments, is: .optional, ofType: Comment3.self, associatedWith: Comment3.keys.postID)
    )
    }
}
