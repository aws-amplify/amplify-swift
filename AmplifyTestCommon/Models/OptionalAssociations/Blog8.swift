//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Blog8: Model {
  public let id: String
  public var name: String
  public var customs: [MyCustomModel8]?
  public var notes: [String]?

  public init(id: String = UUID().uuidString,
      name: String,
      customs: [MyCustomModel8]? = [],
      notes: [String]? = []) {
      self.id = id
      self.name = name
      self.customs = customs
      self.notes = notes
  }
}
