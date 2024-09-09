//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Comment3 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case postID
    case content
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let comment3 = Comment3.keys

    model.pluralName = "Comment3s"

    model.attributes(
      .index(fields: ["postID", "content"], name: "byPost3")
    )

    model.fields(
      .id(),
      .field(comment3.postID, is: .required, ofType: .string),
      .field(comment3.content, is: .required, ofType: .string),
      .field(comment3.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment3.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
