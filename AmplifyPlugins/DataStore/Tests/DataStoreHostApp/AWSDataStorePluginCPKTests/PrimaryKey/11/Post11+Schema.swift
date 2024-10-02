//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Post11 {
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
    let post11 = Post11.keys

    model.pluralName = "Post11s"

    model.attributes(
      .index(fields: ["postId", "sk"], name: nil),
      .primaryKey(fields: [post11.postId, post11.sk])
    )

    model.fields(
      .field(post11.postId, is: .required, ofType: .string),
      .field(post11.sk, is: .required, ofType: .int),
      .field(post11.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post11.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Post11: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension Post11.IdentifierProtocol {
  static func identifier(
    postId: String,
    sk: Int
  ) -> Self {
    .make(fields: [(name: "postId", value: postId), (name: "sk", value: sk)])
  }
}
