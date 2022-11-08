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
    
    public class Path: ModelPath<UserFollowers> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension ModelPath where ModelType == UserFollowers {
    var id: FieldPath<String> { id() }
    var user: ModelPath<User> { User.Path(name: "user", parent: self) }
    var followersUser: ModelPath<User> { User.Path(name: "followersUser", parent: self) }
}
