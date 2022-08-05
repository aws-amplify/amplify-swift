//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct OGCScenarioBPost: Model {
  public let id: String
  public var title: String
  public var owner: String?

  public init(id: String = UUID().uuidString,
      title: String,
      owner: String? = nil) {
      self.id = id
      self.title = title
      self.owner = owner
  }
}
