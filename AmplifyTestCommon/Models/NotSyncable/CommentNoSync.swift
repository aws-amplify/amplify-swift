//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public struct CommentNoSync: Model {

    public let id: String
    public var content: String
    public var createdAt: Date
    public var postNoSync: PostNoSync

    public init(id: String = UUID().uuidString,
                content: String,
                createdAt: Date = Date(),
                postNoSync: PostNoSync) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.postNoSync = postNoSync
    }

}
