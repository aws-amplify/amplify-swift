//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Post6 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case blog
    case comments
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let post6 = Post6.keys

    model.listPluralName = "Post6s"
    model.syncPluralName = "Post6s"

    model.fields(
      .id(),
      .field(post6.title, is: .required, ofType: .string),
      .belongsTo(post6.blog, is: .optional, ofType: Blog6.self, targetName: "blogID"),
      .hasMany(post6.comments, is: .optional, ofType: Comment6.self, associatedWith: Comment6.keys.post)
    )
    }
}
