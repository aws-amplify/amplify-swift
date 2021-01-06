//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct UserFollowing: Model {
  public let id: String
  public var user: User?
  public var followingUser: User?

  public init(id: String = UUID().uuidString,
      user: User? = nil,
      followingUser: User? = nil) {
      self.id = id
      self.user = user
      self.followingUser = followingUser
  }
}
