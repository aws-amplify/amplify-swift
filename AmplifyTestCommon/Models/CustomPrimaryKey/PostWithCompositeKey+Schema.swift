//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension PostWithCompositeKey {
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
    let post22 = PostWithCompositeKey.keys

    model.pluralName = "PostWithCompositeKeys"

    model.attributes(
      .index(fields: ["id", "title"], name: nil),
      .primaryKey(fields: [post22.id, post22.title])
    )

    model.fields(
      .field(post22.id, is: .required, ofType: .string),
      .field(post22.title, is: .required, ofType: .string),
      .hasMany(post22.comments, is: .optional, ofType: CommentWithCompositeKey.self, associatedWith: CommentWithCompositeKey.keys.post),
      .field(post22.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post22.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension PostWithCompositeKey: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias Identifier = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension PostWithCompositeKey.Identifier {
  public static func identifier(id: String,
      title: String) -> Self {
    .make(fields: [(name: "id", value: id), (name: "title", value: title)])
  }
}
