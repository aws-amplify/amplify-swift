//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Post7V2 {
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
    let post7V2 = Post7V2.keys

    model.pluralName = "Post7V2s"

    model.fields(
      .id(),
      .field(post7V2.title, is: .required, ofType: .string),
      .belongsTo(post7V2.blog, is: .optional, ofType: Blog7V2.self, targetName: "blog7V2PostsId"),
      .hasMany(post7V2.comments, is: .optional, ofType: Comment7V2.self, associatedWith: Comment7V2.keys.post),
      .field(post7V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post7V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
