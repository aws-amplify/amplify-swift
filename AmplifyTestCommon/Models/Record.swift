//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Foundation
import Amplify

public struct Record: Model {
    public let id: String
    public var name: String
    public var description: String?
    public var coverId: String?
    public let cover: RecordCover?
    public let createdAt: Temporal.DateTime?
    public let updatedAt: Temporal.DateTime?

    public init(name: String,
                description: String? = nil) {
    self.init(name: name,
              description: description,
              coverId: nil,
              cover: nil,
              createdAt: nil,
              updatedAt: nil)
    }

    internal init(id: String = UUID().uuidString,
                  name: String,
                  description: String? = nil,
                  coverId: String? = nil,
                  cover: RecordCover? = nil,
                  createdAt: Temporal.DateTime? = nil,
                  updatedAt: Temporal.DateTime? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.cover = cover
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

