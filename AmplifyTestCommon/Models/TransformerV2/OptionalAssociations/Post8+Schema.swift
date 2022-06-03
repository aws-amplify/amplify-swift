//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Post8 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case randomId
    case blog
    case comments
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let post8 = Post8.keys

    model.pluralName = "Post8s"

    model.attributes(
      .index(fields: ["blogId"], name: "postByBlog"),
      .index(fields: ["randomId"], name: "byRandom")
    )

    model.fields(
      .id(),
      .field(post8.name, is: .required, ofType: .string),
      .field(post8.randomId, is: .optional, ofType: .string),
      .belongsTo(post8.blog, is: .optional, ofType: Blog8.self, targetName: "blogId"),
      .hasMany(post8.comments, is: .optional, ofType: Comment8.self, associatedWith: Comment8.keys.post),
      .field(post8.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post8.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
