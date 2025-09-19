//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension Blog8 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case name
    case customs
    case notes
    case posts
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let blog8 = Blog8.keys

    model.pluralName = "Blog8s"

    model.fields(
      .id(),
      .field(blog8.name, is: .required, ofType: .string),
      .field(blog8.customs, is: .optional, ofType: .embeddedCollection(of: MyCustomModel8.self)),
      .field(blog8.notes, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .hasMany(blog8.posts, is: .optional, ofType: Post8.self, associatedWith: Post8.keys.blog),
      .field(blog8.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(blog8.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
