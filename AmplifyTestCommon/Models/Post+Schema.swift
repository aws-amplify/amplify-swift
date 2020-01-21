//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Post {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case content
    case createdAt
    case updatedAt
    case draft
    case rating
    case comments
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let post = Post.keys

    model.pluralName = "Posts"

    model.fields(
      .id(),
      .field(post.title, is: .required, ofType: .string),
      .field(post.content, is: .required, ofType: .string),
      .field(post.createdAt, is: .required, ofType: .dateTime),
      .field(post.updatedAt, is: .optional, ofType: .dateTime),
      .field(post.draft, is: .optional, ofType: .bool),
      .field(post.rating, is: .optional, ofType: .double),
      .hasMany(post.comments, is: .optional, ofType: Comment.self, associatedWith: Comment.keys.post)
    )
    }
}
