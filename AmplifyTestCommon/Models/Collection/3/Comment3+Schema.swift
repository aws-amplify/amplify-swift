//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Comment3 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case postID
    case content
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let comment3 = Comment3.keys

    model.listPluralName = "Comment3s"
    model.syncPluralName = "Comment3s"

    model.fields(
      .id(),
      .field(comment3.postID, is: .required, ofType: .string),
      .field(comment3.content, is: .required, ofType: .string)
    )
    }
}
