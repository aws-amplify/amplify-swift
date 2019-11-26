//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

// TODO: Remove once we remove _version
// swiftlint:disable identifier_name
public struct Post: Model {

    public let id: String
    public var title: String
    public var content: String
    public var createdAt: Date
    public var updatedAt: Date?
    public var rating: Double?
    public var draft: Bool?
    public var comments: List<Comment>

    // TODO: Remove this once we get sync metadata wired up
    public var _version: Int?

    public init(id: String = UUID().uuidString,
                title: String,
                content: String,
                createdAt: Date = Date(),
                updatedAt: Date? = nil,
                rating: Double? = nil,
                draft: Bool? = nil,
                _version: Int? = nil,
                comments: List<Comment> = []) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.rating = rating
        self.draft = draft
        self.comments = comments
        self._version = _version
    }

}
