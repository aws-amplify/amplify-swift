//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Post3 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case comments
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let post3 = Post3.keys

    model.listPluralName = "Post3s"
    model.syncPluralName = "Post3s"

    model.fields(
      .id(),
      .field(post3.title, is: .required, ofType: .string),
      .hasMany(post3.comments, is: .optional, ofType: Comment3.self, associatedWith: Comment3.keys.postID)
    )
    }
}
