//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Blog7V2 {
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
    let blog7V2 = Blog7V2.keys

    model.pluralName = "Blog7V2s"

    model.fields(
      .id(),
      .field(blog7V2.name, is: .required, ofType: .string),
      .hasMany(blog7V2.posts, is: .optional, ofType: Post7V2.self, associatedWith: Post7V2.keys.blog),
      .field(blog7V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(blog7V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
