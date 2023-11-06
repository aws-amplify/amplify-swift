//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct TodoCognitoMultiOwner: Model {
  public let id: String
  public var title: String
  public var content: String?
  public var owner: String?
  public var editors: [String?]?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      title: String,
      content: String? = nil,
      owner: String? = nil,
      editors: [String?]? = nil) {
    self.init(id: id,
      title: title,
      content: content,
      owner: owner,
      editors: editors,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      title: String,
      content: String? = nil,
      owner: String? = nil,
      editors: [String?]? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.title = title
      self.content = content
      self.owner = owner
      self.editors = editors
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
