//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Comment7V2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case post
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let comment7V2 = Comment7V2.keys

    model.pluralName = "Comment7V2s"

    model.fields(
      .id(),
      .field(comment7V2.content, is: .optional, ofType: .string),
      .belongsTo(comment7V2.post, is: .optional, ofType: Post7V2.self, targetName: "post7V2CommentsId"),
      .field(comment7V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment7V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
