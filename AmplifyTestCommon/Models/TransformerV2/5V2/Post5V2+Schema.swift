//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Post5V2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case editors
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let post5V2 = Post5V2.keys

    model.pluralName = "Post5V2s"

    model.fields(
      .id(),
      .field(post5V2.title, is: .required, ofType: .string),
      .hasMany(post5V2.editors, is: .optional, ofType: PostEditor5V2.self, associatedWith: PostEditor5V2.keys.post5V2),
      .field(post5V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post5V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
