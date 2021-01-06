//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct User: Model {
  public let id: String
  public var name: String
  public var following: List<UserFollowing>?
  public var followers: List<UserFollowers>?

  public init(id: String = UUID().uuidString,
      name: String,
      following: List<UserFollowing>? = [],
      followers: List<UserFollowers>? = []) {
      self.id = id
      self.name = name
      self.following = following
      self.followers = followers
  }
}
