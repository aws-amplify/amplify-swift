//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Post13 {
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
    let post13 = Post13.keys

    model.pluralName = "Post13s"

    model.attributes(
      .index(fields: ["postId", "sk"], name: nil),
      .primaryKey(fields: [post13.postId, post13.sk])
    )

    model.fields(
      .field(post13.postId, is: .required, ofType: .string),
      .field(post13.sk, is: .required, ofType: .dateTime),
      .field(post13.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post13.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Post13: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension Post13.IdentifierProtocol {
  static func identifier(
    postId: String,
    sk: Temporal.DateTime
  ) -> Self {
    .make(fields: [(name: "postId", value: postId), (name: "sk", value: sk)])
  }
}
