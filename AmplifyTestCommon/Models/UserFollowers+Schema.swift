//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension UserFollowers {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case user
    case followersUser
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let userFollowers = UserFollowers.keys

    model.listPluralName = "UserFollowers"
    model.syncPluralName = "UserFollowers"

    model.fields(
      .id(),
      .belongsTo(userFollowers.user, is: .optional, ofType: User.self, targetName: "userFollowersUserId"),
      .belongsTo(userFollowers.followersUser, is: .optional, ofType: User.self, targetName: "userFollowersFollowersUserId")
    )
    }
}
