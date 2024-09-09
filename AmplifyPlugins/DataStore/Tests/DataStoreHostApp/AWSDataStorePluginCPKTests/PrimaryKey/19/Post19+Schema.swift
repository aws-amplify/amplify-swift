//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Post19 {
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
    let post19 = Post19.keys

    model.pluralName = "Post19s"

    model.attributes(
      .index(fields: ["postId", "sk"], name: nil),
      .primaryKey(fields: [post19.postId, post19.sk])
    )

    model.fields(
      .field(post19.postId, is: .required, ofType: .string),
      .field(post19.sk, is: .required, ofType: .string),
      .field(post19.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post19.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Post19: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension Post19.IdentifierProtocol {
  static func identifier(
    postId: String,
    sk: String
  ) -> Self {
    .make(fields: [(name: "postId", value: postId), (name: "sk", value: sk)])
  }
}
