//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Todo15: Model {
  public let id: String
  public var content: String?
  public var owners: [String?]?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(
    id: String = UUID().uuidString,
    content: String? = nil,
    owners: [String?]? = nil
  ) {
    self.init(
      id: id,
      content: content,
      owners: owners,
      createdAt: nil,
      updatedAt: nil
    )
  }
  init(
    id: String = UUID().uuidString,
    content: String? = nil,
    owners: [String?]? = nil,
    createdAt: Temporal.DateTime? = nil,
    updatedAt: Temporal.DateTime? = nil
  ) {
      self.id = id
      self.content = content
      self.owners = owners
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
