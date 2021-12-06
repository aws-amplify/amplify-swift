//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public class Team4bV2: Model {
  public let id: String
  public var name: String
  public var project: Project4bV2?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

    public convenience init(id: String = UUID().uuidString,
      name: String,
      project: Project4bV2? = nil) {
    self.init(id: id,
      name: name,
      project: project,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String,
      project: Project4bV2? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.project = project
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
