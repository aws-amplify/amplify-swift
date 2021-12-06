//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Post6V2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case blog
    case comments
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let post6V2 = Post6V2.keys

    model.authRules = [
      rule(allow: .public, operations: [.create, .update, .delete, .read])
    ]

    model.pluralName = "Post6V2s"

    model.attributes(
      .index(fields: ["blogID"], name: "byBlog")
    )

    model.fields(
      .id(),
      .field(post6V2.title, is: .required, ofType: .string),
      .belongsTo(post6V2.blog, is: .optional, ofType: Blog6V2.self, targetName: "blogID"),
      .hasMany(post6V2.comments, is: .optional, ofType: Comment6V2.self, associatedWith: Comment6V2.keys.post),
      .field(post6V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post6V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
