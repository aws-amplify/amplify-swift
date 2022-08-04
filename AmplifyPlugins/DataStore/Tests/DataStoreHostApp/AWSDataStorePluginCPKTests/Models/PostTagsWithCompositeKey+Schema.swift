//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension PostTagsWithCompositeKey {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case postWithTagsCompositeKey
    case tagWithCompositeKey
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let postTagsWithCompositeKey = PostTagsWithCompositeKey.keys

    model.pluralName = "PostTagsWithCompositeKeys"

    model.attributes(
      .index(fields: ["postWithTagsCompositeKeyID", "postWithTagsCompositeKeytitle"], name: "byPostWithTagsCompositeKey"),
      .index(fields: ["tagWithCompositeKeyID", "tagWithCompositeKeyname"], name: "byTagWithCompositeKey"),
      .primaryKey(fields: [postTagsWithCompositeKey.id])
    )

    model.fields(
      .field(postTagsWithCompositeKey.id, is: .required, ofType: .string),
      .belongsTo(postTagsWithCompositeKey.postWithTagsCompositeKey, is: .required, ofType: PostWithTagsCompositeKey.self, targetNames: ["postWithTagsCompositeKeyID", "postWithTagsCompositeKeytitle"]),
      .belongsTo(postTagsWithCompositeKey.tagWithCompositeKey, is: .required, ofType: TagWithCompositeKey.self, targetNames: ["tagWithCompositeKeyID", "tagWithCompositeKeyname"]),
      .field(postTagsWithCompositeKey.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(postTagsWithCompositeKey.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension PostTagsWithCompositeKey: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias Identifier = DefaultModelIdentifier<Self>
}
