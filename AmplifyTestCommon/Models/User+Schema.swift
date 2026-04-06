//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension User {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case name
    case following
    case followers
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
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

    class Path: ModelPath<User> {}

    static var rootPath: PropertyContainerPath? { Path() }
}

extension ModelPath where ModelType == User {
    var id: FieldPath<String> { id() }
    var name: FieldPath<String> { string("name") }
    var following: ModelPath<UserFollowing> { UserFollowing.Path(name: "following", isCollection: true, parent: self) }
    var followers: ModelPath<UserFollowers> { UserFollowers.Path(name: "followers", isCollection: true, parent: self) }

}

