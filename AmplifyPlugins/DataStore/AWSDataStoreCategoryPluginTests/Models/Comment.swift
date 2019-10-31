//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public struct Comment: Model {

    public let id: String
    public let content: String
    public let createdAt: Date
    public let post: Post

    public init(id: String = UUID().uuidString,
                content: String,
                createdAt: Date = Date(),
                post: Post) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.post = post
    }

}
