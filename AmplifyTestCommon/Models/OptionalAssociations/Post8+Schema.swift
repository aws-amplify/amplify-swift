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
    case blog_id
    case random_id
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let post8 = Post8.keys

    model.pluralName = "Post8s"

    model.fields(
      .id(),
      .field(post8.name, is: .required, ofType: .string),
      .field(post8.blog_id, is: .optional, ofType: .string),
      .field(post8.random_id, is: .optional, ofType: .string)
    )
    }
}
