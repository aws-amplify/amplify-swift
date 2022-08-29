//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Meeting8V2: Model {
  public let id: String
  public var title: String
  public var attendees: List<Registration8V2>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      title: String,
      attendees: List<Registration8V2>? = []) {
    self.init(id: id,
      title: title,
      attendees: attendees,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      title: String,
      attendees: List<Registration8V2>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.title = title
      self.attendees = attendees
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
