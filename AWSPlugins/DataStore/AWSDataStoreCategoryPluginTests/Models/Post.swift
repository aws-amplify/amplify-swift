//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public struct Post: Model {

    public let id: String
    public let title: String
    public let content: String
    public let createdAt: Date
    public let updatedAt: Date?
    public let draft: Bool
    public let comments: [Comment]?

    public init(id: String = UUID().uuidString,
                title: String,
                content: String,
                createdAt: Date = Date(),
                updatedAt: Date? = nil,
                draft: Bool = false,
                comments: [Comment] = []) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.draft = draft
        self.comments = comments
    }

}
