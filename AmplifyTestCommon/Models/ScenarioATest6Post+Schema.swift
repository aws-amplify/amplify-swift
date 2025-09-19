//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension ScenarioATest6Post {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case title
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let scenarioATest6Post = ScenarioATest6Post.keys

    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "sub", operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "ScenarioATest6Posts"
    model.syncPluralName = "ScenarioATest6Posts"

    model.fields(
      .id(),
      .field(scenarioATest6Post.title, is: .required, ofType: .string)
    )
    }
}
