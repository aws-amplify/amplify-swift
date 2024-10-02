//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Post14 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case postId
    case sk
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let post14 = Post14.keys

    model.pluralName = "Post14s"

    model.attributes(
      .index(fields: ["postId", "sk"], name: nil),
      .primaryKey(fields: [post14.postId, post14.sk])
    )

    model.fields(
      .field(post14.postId, is: .required, ofType: .string),
      .field(post14.sk, is: .required, ofType: .date),
      .field(post14.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post14.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Post14: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension Post14.IdentifierProtocol {
  static func identifier(
    postId: String,
    sk: Temporal.Date
  ) -> Self {
    .make(fields: [(name: "postId", value: postId), (name: "sk", value: sk)])
  }
}
