//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension PostWithCompositeKeyUnidirectional {
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
    let postWithCompositeKeyUnidirectional = PostWithCompositeKeyUnidirectional.keys

    model.pluralName = "PostWithCompositeKeyUnidirectionals"

    model.attributes(
      .index(fields: ["id", "title"], name: nil),
      .primaryKey(fields: [postWithCompositeKeyUnidirectional.id, postWithCompositeKeyUnidirectional.title])
    )

    model.fields(
      .field(postWithCompositeKeyUnidirectional.id, is: .required, ofType: .string),
      .field(postWithCompositeKeyUnidirectional.title, is: .required, ofType: .string),
      .hasMany(postWithCompositeKeyUnidirectional.comments,
               is: .optional,
               ofType: CommentWithCompositeKeyUnidirectional.self,
               associatedWith: CommentWithCompositeKeyUnidirectional.keys.postWithCompositeKeyUnidirectionalCommentsId),
      .field(postWithCompositeKeyUnidirectional.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(postWithCompositeKeyUnidirectional.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension PostWithCompositeKeyUnidirectional: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension PostWithCompositeKeyUnidirectional.IdentifierProtocol {
  public static func identifier(id: String,
      title: String) -> Self {
    .make(fields: [(name: "id", value: id), (name: "title", value: title)])
  }
}
