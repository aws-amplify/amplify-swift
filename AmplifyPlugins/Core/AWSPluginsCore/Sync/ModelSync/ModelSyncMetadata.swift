//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public struct ModelSyncMetadata: Model {
    public let id: String
    public var lastSync: Int?
    public var startedAt: Date?

    public init(id: String,
                lastSync: Int?,
                startedAt: Date?) {
        self.id = id
        self.lastSync = lastSync
        self.startedAt = startedAt
    }
}
