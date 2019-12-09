//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Post: Model {
  public let id: String
  public var title: String
  public var content: String
  public var createdAt: Date
  public var updatedAt: Date?
  public var draft: Bool?
  public var rating: Double?
  public var comments: List<Comment>?

  public init(id: String = UUID().uuidString,
      title: String,
      content: String,
      createdAt: Date,
      updatedAt: Date? = nil,
      draft: Bool? = nil,
      rating: Double? = nil,
      comments: List<Comment>? = []) {
      self.id = id
      self.title = title
      self.content = content
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.draft = draft
      self.rating = rating
      self.comments = comments
  }
}
