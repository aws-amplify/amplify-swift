//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct PostEditor5V2: Model {
  public let id: String
  public var post5V2: Post5V2
  public var user5V2: User5V2
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      post5V2: Post5V2,
      user5V2: User5V2) {
    self.init(id: id,
      post5V2: post5V2,
      user5V2: user5V2,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      post5V2: Post5V2,
      user5V2: User5V2,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.post5V2 = post5V2
      self.user5V2 = user5V2
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
