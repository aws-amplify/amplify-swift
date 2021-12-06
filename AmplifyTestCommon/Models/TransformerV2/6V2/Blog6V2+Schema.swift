//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Blog6V2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case posts
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let blog6V2 = Blog6V2.keys

    model.authRules = [
      rule(allow: .public, operations: [.create, .update, .delete, .read])
    ]

    model.pluralName = "Blog6V2s"

    model.fields(
      .id(),
      .field(blog6V2.name, is: .required, ofType: .string),
      .hasMany(blog6V2.posts, is: .optional, ofType: Post6V2.self, associatedWith: Post6V2.keys.blog),
      .field(blog6V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(blog6V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
