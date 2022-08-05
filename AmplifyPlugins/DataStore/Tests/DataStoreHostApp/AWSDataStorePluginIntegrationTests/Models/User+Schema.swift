//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension User {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case following
    case followers
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let user = User.keys

    model.listPluralName = "Users"
    model.syncPluralName = "Users"

    model.fields(
      .id(),
      .field(user.name, is: .required, ofType: .string),
      .hasMany(user.following, is: .optional, ofType: UserFollowing.self, associatedWith: UserFollowing.keys.user),
      .hasMany(user.followers, is: .optional, ofType: UserFollowers.self, associatedWith: UserFollowers.keys.user)
    )
    }
}
