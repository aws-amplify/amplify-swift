//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Post7 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case postId
    case title
    case comments
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let post7 = Post7.keys

    model.pluralName = "Post7s"

    model.attributes(
      .index(fields: ["postId", "title"], name: nil),
      .primaryKey(fields: [post7.postId, post7.title])
    )

    model.fields(
      .field(post7.postId, is: .required, ofType: .string),
      .field(post7.title, is: .required, ofType: .string),
      .hasMany(post7.comments, is: .optional, ofType: Comment7.self, associatedWith: Comment7.keys.post),
      .field(post7.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post7.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Post7: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension Post7.IdentifierProtocol {
  static func identifier(
    postId: String,
    title: String
  ) -> Self {
    .make(fields: [(name: "postId", value: postId), (name: "title", value: title)])
  }
}
