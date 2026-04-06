//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension UserFollowing {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case user
    case followingUser
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let userFollowing = UserFollowing.keys

    model.listPluralName = "UserFollowings"
    model.syncPluralName = "UserFollowings"

    model.fields(
      .id(),
      .belongsTo(userFollowing.user, is: .optional, ofType: User.self, targetName: "userFollowingUserId"),
      .belongsTo(userFollowing.followingUser, is: .optional, ofType: User.self, targetName: "userFollowingFollowingUserId")
    )
    }

    class Path: ModelPath<UserFollowing> {}

    static var rootPath: PropertyContainerPath? { Path() }
}

extension ModelPath where ModelType == UserFollowing {
    var id: FieldPath<String> { id() }
    var user: ModelPath<User> { User.Path(name: "user", parent: self) }
    var followingUser: ModelPath<User> { User.Path(name: "followingUser", parent: self) }
}
