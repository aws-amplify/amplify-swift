//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Project: Model {
  public let id: String
  public var name: String?
  public var team: Team?

  public init(id: String = UUID().uuidString,
      name: String? = nil,
      team: Team? = nil) {
      self.id = id
      self.name = name
      self.team = team
  }
}
