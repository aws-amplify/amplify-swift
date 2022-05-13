//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct ModelExplicitCustomPk: Model {
  public let userId: String
  public var name: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(userId: String, name: String? = nil) {
    self.init(userId: userId,
              name: name,
              createdAt: nil,
              updatedAt: nil)
  }
  internal init(userId: String,
                name: String? = nil,
                createdAt: Temporal.DateTime? = nil,
                updatedAt: Temporal.DateTime? = nil) {
      self.userId = userId
      self.name = name
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
