//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Team2: Model {
  public let id: String
  public var name: String

  public init(id: String = UUID().uuidString,
      name: String) {
      self.id = id
      self.name = name
  }
}
