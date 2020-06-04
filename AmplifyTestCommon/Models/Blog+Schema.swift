//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Blog {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case createdAt
    case posts
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let blog = Blog.keys

    model.pluralName = "Blogs"

    model.fields(
      .id(),
      .field(blog.title, is: .required, ofType: .string),
      .field(blog.createdAt, is: .required, ofType: .dateTime),
      .hasMany(blog.posts, is: .optional, ofType: Post.self, associatedWith: Post.keys.blog)
    )
    }
}
