//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension M2MPost {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case editors
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let m2MPost = M2MPost.keys

    model.listPluralName = "M2MPosts"
    model.syncPluralName = "M2MPosts"

    model.fields(
      .id(),
      .field(m2MPost.title, is: .required, ofType: .string),
      .hasMany(m2MPost.editors, is: .optional, ofType: M2MPostEditor.self, associatedWith: M2MPostEditor.keys.post)
    )
    }
}
