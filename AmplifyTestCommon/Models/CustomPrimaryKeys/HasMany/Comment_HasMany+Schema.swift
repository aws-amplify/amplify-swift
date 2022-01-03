//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Comment_HasMany_1toM_Case1_v1 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case postID
    case content
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let comment_HasMany_1toM_Case1_v1 = Comment_HasMany_1toM_Case1_v1.keys

    model.pluralName = "Comment_HasMany_1toM_Case1_v1s"

    model.attributes(
      .index(fields: ["postID", "content"], name: "byPost")
    )

    model.fields(
      .id(),
      .field(comment_HasMany_1toM_Case1_v1.postID, is: .required, ofType: .string),
      .field(comment_HasMany_1toM_Case1_v1.content, is: .required, ofType: .string),
      .field(comment_HasMany_1toM_Case1_v1.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment_HasMany_1toM_Case1_v1.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Comment_HasMany_1toM_Case2_v1 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case commentID
    case postID
    case content
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let comment_HasMany_1toM_Case2_v1 = Comment_HasMany_1toM_Case2_v1.keys

    model.pluralName = "Comment_HasMany_1toM_Case2_v1s"

    model.attributes(
      .index(fields: ["commentID"], name: nil),
      .index(fields: ["postID", "content"], name: "byPost")
    )

    model.fields(
      .id(),
      .field(comment_HasMany_1toM_Case2_v1.commentID, is: .required, ofType: .string),
      .field(comment_HasMany_1toM_Case2_v1.postID, is: .required, ofType: .string),
      .field(comment_HasMany_1toM_Case2_v1.content, is: .required, ofType: .string),
      .field(comment_HasMany_1toM_Case2_v1.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment_HasMany_1toM_Case2_v1.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Comment_HasMany_1toM_Case3_v1 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case commentID
    case postID
    case content
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let comment_HasMany_1toM_Case3_v1 = Comment_HasMany_1toM_Case3_v1.keys

    model.pluralName = "Comment_HasMany_1toM_Case3_v1s"

    model.attributes(
      .index(fields: ["commentID"], name: nil),
      .index(fields: ["postID", "content"], name: "byPost")
    )

    model.fields(
      .id(),
      .field(comment_HasMany_1toM_Case3_v1.commentID, is: .required, ofType: .string),
      .field(comment_HasMany_1toM_Case3_v1.postID, is: .required, ofType: .string),
      .field(comment_HasMany_1toM_Case3_v1.content, is: .required, ofType: .string),
      .field(comment_HasMany_1toM_Case3_v1.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment_HasMany_1toM_Case3_v1.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
