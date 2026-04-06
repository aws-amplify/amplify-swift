//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension Comment4 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case content
    case post
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let comment4 = Comment4.keys

    model.listPluralName = "Comment4s"
    model.syncPluralName = "Comment4s"

    model.fields(
      .id(),
      .field(comment4.content, is: .required, ofType: .string),
      .belongsTo(comment4.post, is: .optional, ofType: Post4.self, targetName: "postID")
    )
    }
}
