//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

// swiftlint:disable identifier_name
public struct PostNoSync: Model {

    public let id: String
    public var title: String
    public var content: String
    public var createdAt: Date
    public var updatedAt: Date?
    public var rating: Double?
    public var draft: Bool?
    public var commentNoSyncs: List<CommentNoSync>?

    public init(id: String = UUID().uuidString,
                title: String,
                content: String,
                createdAt: Date = Date(),
                updatedAt: Date? = nil,
                rating: Double? = nil,
                draft: Bool? = nil,
                _version: Int? = nil,
                _deleted: Bool? = nil,
                commentNoSyncs: List<CommentNoSync> = []) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.rating = rating
        self.draft = draft
        self.commentNoSyncs = commentNoSyncs
    }

}
