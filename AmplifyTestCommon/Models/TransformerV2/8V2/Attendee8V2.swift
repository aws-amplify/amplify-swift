//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Attendee8V2: Model {
  public let id: String
  public var meetings: List<Registration8V2>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      meetings: List<Registration8V2>? = []) {
    self.init(id: id,
      meetings: meetings,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      meetings: List<Registration8V2>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.meetings = meetings
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
