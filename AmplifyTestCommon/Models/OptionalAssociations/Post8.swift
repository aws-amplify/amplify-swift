//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Post8: Model {
  public let id: String
  public var name: String
  public var blog_id: String?
  public var random_id: String?

  public init(id: String = UUID().uuidString,
      name: String,
      blog_id: String? = nil,
      random_id: String? = nil) {
      self.id = id
      self.name = name
      self.blog_id = blog_id
      self.random_id = random_id
  }
}
