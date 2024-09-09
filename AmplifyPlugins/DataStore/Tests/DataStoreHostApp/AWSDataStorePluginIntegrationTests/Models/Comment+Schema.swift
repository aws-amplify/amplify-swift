//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Comment {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case content
    case createdAt
    case post
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let comment = Comment.keys

    model.listPluralName = "Comments"
    model.syncPluralName = "Comments"

    model.fields(
      .id(),
      .field(comment.content, is: .required, ofType: .string),
      .field(comment.createdAt, is: .required, ofType: .dateTime),
      .belongsTo(comment.post, is: .required, ofType: Post.self, targetName: "commentPostId")
    )
    }
}
