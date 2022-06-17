//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Comment8 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case post
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let comment8 = Comment8.keys

    model.pluralName = "Comment8s"

    model.attributes(
      .index(fields: ["postId"], name: "commentByPost")
    )

    model.fields(
      .id(),
      .field(comment8.content, is: .optional, ofType: .string),
      .belongsTo(comment8.post, is: .optional, ofType: Post8.self, targetName: "postId"),
      .field(comment8.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment8.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
