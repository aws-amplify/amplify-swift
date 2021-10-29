//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Comment6 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case post
    case content
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let comment6 = Comment6.keys

    model.listPluralName = "Comment6s"
    model.syncPluralName = "Comment6s"

    model.fields(
      .id(),
      .belongsTo(comment6.post, is: .optional, ofType: Post6.self, targetName: "postID"),
      .field(comment6.content, is: .required, ofType: .string)
    )
    }
}
