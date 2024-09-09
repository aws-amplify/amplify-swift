//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension PostEditor5 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case post
    case editor
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let postEditor5 = PostEditor5.keys

    model.listPluralName = "PostEditor5s"
    model.syncPluralName = "PostEditor5s"

    model.fields(
      .id(),
      .belongsTo(postEditor5.post, is: .required, ofType: Post5.self, targetName: "postID"),
      .belongsTo(postEditor5.editor, is: .required, ofType: User5.self, targetName: "editorID")
    )
    }
}
