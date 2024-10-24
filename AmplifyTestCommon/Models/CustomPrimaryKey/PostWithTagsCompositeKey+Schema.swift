//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension PostWithTagsCompositeKey {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case postId
    case title
    case tags
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let postWithTagsCompositeKey = PostWithTagsCompositeKey.keys

    model.pluralName = "PostWithTagsCompositeKeys"

    model.attributes(
      .index(fields: ["postId", "title"], name: nil),
      .primaryKey(fields: [postWithTagsCompositeKey.postId, postWithTagsCompositeKey.title])
    )

    model.fields(
      .field(postWithTagsCompositeKey.postId, is: .required, ofType: .string),
      .field(postWithTagsCompositeKey.title, is: .required, ofType: .string),
      .hasMany(postWithTagsCompositeKey.tags, is: .optional, ofType: PostTagsWithCompositeKey.self, associatedWith: PostTagsWithCompositeKey.keys.postWithTagsCompositeKey),
      .field(postWithTagsCompositeKey.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(postWithTagsCompositeKey.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension PostWithTagsCompositeKey: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension PostWithTagsCompositeKey.IdentifierProtocol {
  static func identifier(
    postId: String,
    title: String
  ) -> Self {
    .make(fields: [(name: "postId", value: postId), (name: "title", value: title)])
  }
}
