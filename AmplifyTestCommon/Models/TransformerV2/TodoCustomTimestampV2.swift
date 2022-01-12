//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct TodoCustomTimestampV2: Model {
  public let id: String
  public var content: String?
  public var createdOn: Temporal.DateTime?
  public var updatedOn: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      content: String? = nil) {
    self.init(id: id,
      content: content,
      createdOn: nil,
      updatedOn: nil)
  }
  internal init(id: String = UUID().uuidString,
      content: String? = nil,
      createdOn: Temporal.DateTime? = nil,
      updatedOn: Temporal.DateTime? = nil) {
      self.id = id
      self.content = content
      self.createdOn = createdOn
      self.updatedOn = updatedOn
  }
}
