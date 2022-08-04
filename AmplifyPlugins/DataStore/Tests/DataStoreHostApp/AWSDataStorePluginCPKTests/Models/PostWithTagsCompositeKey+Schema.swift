//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension PostWithTagsCompositeKey {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case postId
    case title
    case tags
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
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
  public typealias Identifier = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension PostWithTagsCompositeKey.Identifier {
  public static func identifier(postId: String,
      title: String) -> Self {
    .make(fields: [(name: "postId", value: postId), (name: "title", value: title)])
  }
}
