//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension UserFollowers {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case user
    case followersUser
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let userFollowers = UserFollowers.keys

    model.listPluralName = "UserFollowers"
    model.syncPluralName = "UserFollowers"

    model.fields(
      .id(),
      .belongsTo(userFollowers.user, is: .optional, ofType: User.self, targetName: "userFollowersUserId"),
      .belongsTo(userFollowers.followersUser, is: .optional, ofType: User.self, targetName: "userFollowersFollowersUserId")
    )
    }

    class Path: ModelPath<UserFollowers> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension ModelPath where ModelType == UserFollowers {
    var id: FieldPath<String> { id() }
    var user: ModelPath<User> { User.Path(name: "user", parent: self) }
    var followersUser: ModelPath<User> { User.Path(name: "followersUser", parent: self) }
}
