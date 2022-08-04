//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Post3V2 {
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
    let post3V2 = Post3V2.keys

    model.authRules = [
      rule(allow: .public, operations: [.create, .update, .delete, .read])
    ]

    model.pluralName = "Post3V2s"

    model.fields(
      .id(),
      .field(post3V2.title, is: .required, ofType: .string),
      .hasMany(post3V2.comments, is: .optional, ofType: Comment3V2.self, associatedWith: Comment3V2.keys.postID),
      .field(post3V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post3V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
