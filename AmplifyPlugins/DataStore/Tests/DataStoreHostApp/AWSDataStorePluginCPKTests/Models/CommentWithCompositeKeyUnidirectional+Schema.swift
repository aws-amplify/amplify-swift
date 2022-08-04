//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension CommentWithCompositeKeyUnidirectional {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case createdAt
    case updatedAt
    case postWithCompositeKeyUnidirectionalCommentsId
    case postWithCompositeKeyUnidirectionalCommentsTitle
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let commentWithCompositeKeyUnidirectional = CommentWithCompositeKeyUnidirectional.keys

    model.pluralName = "CommentWithCompositeKeyUnidirectionals"

    model.attributes(
      .index(fields: ["id", "content"], name: nil),
      .primaryKey(fields: [commentWithCompositeKeyUnidirectional.id, commentWithCompositeKeyUnidirectional.content])
    )

    model.fields(
      .field(commentWithCompositeKeyUnidirectional.id, is: .required, ofType: .string),
      .field(commentWithCompositeKeyUnidirectional.content, is: .required, ofType: .string),
      .field(commentWithCompositeKeyUnidirectional.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(commentWithCompositeKeyUnidirectional.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(commentWithCompositeKeyUnidirectional.postWithCompositeKeyUnidirectionalCommentsId, is: .optional, ofType: .string),
      .field(commentWithCompositeKeyUnidirectional.postWithCompositeKeyUnidirectionalCommentsTitle, is: .optional, ofType: .string)
    )
    }
}

extension CommentWithCompositeKeyUnidirectional: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias Identifier = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension CommentWithCompositeKeyUnidirectional.Identifier {
  public static func identifier(id: String,
      content: String) -> Self {
    .make(fields: [(name: "id", value: id), (name: "content", value: content)])
  }
}
