//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct ModelCustomPkDefined: Model {
  public let id: String
  public let dob: Temporal.DateTime
  public var name: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      dob: Temporal.DateTime,
      name: String? = nil) {
    self.init(id: id,
      dob: dob,
      name: name,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      dob: Temporal.DateTime,
      name: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.dob = dob
      self.name = name
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
