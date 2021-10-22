//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension UserFollowing {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case user
    case followingUser
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let userFollowing = UserFollowing.keys

    model.listPluralName = "UserFollowings"
    model.syncPluralName = "UserFollowings"

    model.fields(
      .id(),
      .belongsTo(userFollowing.user, is: .optional, ofType: User.self, targetName: "userFollowingUserId"),
      .belongsTo(userFollowing.followingUser, is: .optional, ofType: User.self, targetName: "userFollowingFollowingUserId")
    )
    }
}
