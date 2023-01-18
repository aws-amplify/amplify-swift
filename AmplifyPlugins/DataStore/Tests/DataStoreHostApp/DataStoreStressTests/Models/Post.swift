//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Post: Model {
  public let id: String
  public var title: String
  public var status: PostStatus
  public var content: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      title: String,
      status: PostStatus,
      content: String) {
    self.init(id: id,
      title: title,
      status: status,
      content: content,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      title: String,
      status: PostStatus,
      content: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.title = title
      self.status = status
      self.content = content
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
