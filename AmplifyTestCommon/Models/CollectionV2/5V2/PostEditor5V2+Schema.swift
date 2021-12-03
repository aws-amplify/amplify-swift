//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension PostEditor5V2 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case post5V2
    case user5V2
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let postEditor5V2 = PostEditor5V2.keys

    model.pluralName = "PostEditor5V2s"

    model.fields(
      .id(),
      .belongsTo(postEditor5V2.post5V2, is: .required, ofType: Post5V2.self, targetName: "post5V2ID"),
      .belongsTo(postEditor5V2.user5V2, is: .required, ofType: User5V2.self, targetName: "user5V2ID"),
      .field(postEditor5V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(postEditor5V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
