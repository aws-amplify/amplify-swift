//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents a record stored locally
package struct Record: Sendable {
    package let id: Int64
    package let streamName: String
    package let partitionKey: String?
    package let data: Data
    package var dataSize: Int {
        data.count + (partitionKey?.utf8.count ?? 0)
    }
    package let retryCount: Int
    package let createdAt: Date

    package init(
        id: Int64,
        streamName: String,
        partitionKey: String?,
        data: Data,
        retryCount: Int,
        createdAt: Date
    ) {
        self.id = id
        self.streamName = streamName
        self.partitionKey = partitionKey
        self.data = data
        self.retryCount = retryCount
        self.createdAt = createdAt
    }
}

/// Input for recording a new record
package struct RecordInput: Sendable {
    package let streamName: String
    package let partitionKey: String?
    package let data: Data
    package var dataSize: Int {
        data.count + (partitionKey?.utf8.count ?? 0)
    }

    package init(streamName: String, partitionKey: String? = nil, data: Data) {
        self.streamName = streamName
        self.partitionKey = partitionKey
        self.data = data
    }
}
