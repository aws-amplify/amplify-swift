//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension PostWithCompositeKeyAndIndex {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case comments
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let postWithCompositeKeyAndIndex = PostWithCompositeKeyAndIndex.keys

    model.pluralName = "PostWithCompositeKeyAndIndices"

    model.attributes(
      .index(fields: ["id", "title"], name: nil),
      .primaryKey(fields: [postWithCompositeKeyAndIndex.id, postWithCompositeKeyAndIndex.title])
    )

    model.fields(
      .field(postWithCompositeKeyAndIndex.id, is: .required, ofType: .string),
      .field(postWithCompositeKeyAndIndex.title, is: .required, ofType: .string),
      .hasMany(postWithCompositeKeyAndIndex.comments, is: .optional, ofType: CommentWithCompositeKeyAndIndex.self, associatedWith: CommentWithCompositeKeyAndIndex.keys.post),
      .field(postWithCompositeKeyAndIndex.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(postWithCompositeKeyAndIndex.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension PostWithCompositeKeyAndIndex: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension PostWithCompositeKeyAndIndex.IdentifierProtocol {
  public static func identifier(id: String,
      title: String) -> Self {
    .make(fields: [(name: "id", value: id), (name: "title", value: title)])
  }
}
